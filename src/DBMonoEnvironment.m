//
//  DBMonoEnvironment.m
//  Dumbarton
//
//  Copyright (C) 2005, 2006 imeem, inc. All rights reserved.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// 
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//

#import <Foundation/Foundation.h>
#import "DBMonoEnvironment.h"
#import "DBInvoke.h"
#import "DBMonoRegisteredThread.h"

#include <mach/mach_port.h>

#define DB_EXC_HANDLER_COUNT 64
#define DB_EXC_MSG_SIZE 512

static DBMonoEnvironment *_defaultEnvironment = nil;

typedef struct _ExceptionPorts {
    mach_msg_type_number_t maskCount;
    exception_mask_t       masks[DB_EXC_HANDLER_COUNT];
    exception_handler_t    handlers[DB_EXC_HANDLER_COUNT];
    exception_behavior_t   behaviors[DB_EXC_HANDLER_COUNT];
    thread_state_flavor_t  flavors[DB_EXC_HANDLER_COUNT];
} DBExceptionPorts;

static mach_port_name_t exception_port = MACH_PORT_NULL;
static DBExceptionPorts *oldHandlerData = NULL;

@interface DBMonoEnvironment (ExceptionHandling)
- (void)installMachExceptionHandler;
- (void)machExceptionHandlerThread:(id)arg;
@end

@implementation DBMonoEnvironment

+ (DBMonoEnvironment *)defaultEnvironment {
	if(!_defaultEnvironment) {
		_defaultEnvironment = [[DBMonoEnvironment alloc] initWithDomainName:"dumbarton"];
	}
		
	return(_defaultEnvironment);
}

+ (DBMonoEnvironment *)defaultEnvironmentWithName:(const char *)domainName {
	if(!_defaultEnvironment) {
		_defaultEnvironment = [[DBMonoEnvironment alloc] initWithDomainName:(domainName == NULL ? "dumbarton" : domainName)];
	}
	
	return(_defaultEnvironment);
}

- (id)initWithDomainName:(const char *)domainName {
	self = [super init];
	
	if(self) {
		//XXX: this is turned on by default in mono SVN. We should remove this line when 1.1.9 comes out.
		mono_set_defaults(0, mono_parse_default_optimizations(NULL));	
		
		exception_port = MACH_PORT_NULL;

		_monoDomain = mono_jit_init(domainName);
	}
	
	return(self);
}

- (void)dealloc {	
	[super dealloc];
}

+ (MonoClass *)monoClassWithName:(char *)className fromAssembly:(MonoAssembly *)assembly {
	MonoType *monoType = mono_reflection_type_from_name(className, (MonoImage *)mono_assembly_get_image(assembly));
	return(mono_class_from_mono_type(monoType));
}

+ (MonoClass *)corlibMonoClassWithName:(char *)className {
	MonoType *monoType = mono_reflection_type_from_name(className, mono_get_corlib());
	return(mono_class_from_mono_type(monoType));
}

- (MonoDomain *)monoDomain {
	return(_monoDomain);
}

- (MonoAssembly *)openAssemblyWithPath:(NSString *)assemblyPath {
	return(mono_domain_assembly_open(_monoDomain, [assemblyPath fileSystemRepresentation]));
}

+ (void)setAssemblyRoot:(NSString *)assemblyRoot {
	mono_assembly_setrootdir([assemblyRoot fileSystemRepresentation]);
}

+ (void)setConfigDir:(NSString *)configDir {
	mono_set_config_dir([configDir fileSystemRepresentation]);
}

- (void)mapDLL:(const char *)dllName dllPath:(NSString *)dllPath {
	mono_dllmap_insert(NULL, dllName, NULL, [dllPath fileSystemRepresentation], NULL);
}

- (void)registerInternalCall:(const char *)callName callPointer:(const void *)callPointer {
	mono_add_internal_call(callName, callPointer);
}

- (int)executeAssembly:(MonoAssembly *)assembly prepareThreading:(bool)prepareThreading argCount:(int)argCount arguments:(char *[])args {
	if(prepareThreading) {
		//this thread is launched just to force cocoa into multithreaded mode.
		[NSThread detachNewThreadSelector:@selector(nothingThread:) toTarget:self withObject:nil];
		//get DBMonoRegisteredThread to pose as NSThread.
		[DBMonoRegisteredThread poseAsClass:[NSThread class]];
	}
	
#ifndef DEBUG
	[self installMachExceptionHandler];
#endif
	
	mono_jit_exec(_monoDomain, assembly, argCount, args);
	int retVal = mono_environment_exitcode_get();
	mono_jit_cleanup(_monoDomain);
	
	return(retVal);
}

//this thread is launched just to force cocoa into multithreaded mode.
- (void)nothingThread:(id)arg {
	//nothing actually goes on here.
}

// Install an exception handler so that things don't break as badly
- (void)installMachExceptionHandler {
	mach_port_name_t task;

	if (exception_port != MACH_PORT_NULL)
		return;
		
	int rc = 0;

	DBExceptionPorts *ports = oldHandlerData = NSZoneMalloc([self zone], sizeof(DBExceptionPorts));
    memset(ports, 0, sizeof(*ports));

    ports->maskCount = sizeof(ports->masks)/sizeof(ports->masks[0]);

    rc = task_get_exception_ports(mach_task_self(), EXC_MASK_ALL, ports->masks, &ports->maskCount, ports->handlers, ports->behaviors, ports->flavors);

    if (rc != KERN_SUCCESS) {
#if DEBUG
		NSLog(@"Unable to get old task exception ports, krc =  %d, %s", rc, mach_error_string(rc));
#endif
		return;
	}

	rc = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &exception_port);
	
	if (rc != KERN_SUCCESS) {
#if DEBUG
		NSLog(@"mach_port_allocate %d", rc);
#endif
		return;
	}

	rc = mach_port_insert_right(mach_task_self(), exception_port, exception_port, MACH_MSG_TYPE_MAKE_SEND);
	
	if (rc != KERN_SUCCESS) {
#if DEBUG
		NSLog(@"mach_port_insert_right %d", rc);
#endif
		return;
	}

	rc = task_for_pid(mach_task_self(), getpid(), &task);
	
	if (rc != KERN_SUCCESS) {
#if DEBUG
		NSLog(@"task_for_pid %d", rc);
#endif
		return;
	}
	
	rc = task_set_exception_ports(task, EXC_MASK_ALL & ~(EXC_MASK_MACH_SYSCALL | EXC_MASK_SYSCALL | EXC_MASK_RPC_ALERT),
		exception_port, EXCEPTION_DEFAULT, THREAD_STATE_NONE); 

	if (rc != KERN_SUCCESS) {
#if DEBUG
		NSLog(@"task_set_exception_ports %d", rc);
#endif
		return;
	}

	[NSThread detachNewThreadSelector:@selector(machExceptionHandlerThread:) toTarget:self withObject:nil];
}

- (void)machExceptionHandlerThread:(id)arg {
	int r;
	
	// loop and wait for pending exceptions
	for(;;) {
		// Initialize an empty message and reply message
		mach_msg_header_t *msg;
		mach_msg_header_t *reply;
	
		msg = malloc(DB_EXC_MSG_SIZE);
		reply = malloc(DB_EXC_MSG_SIZE);

		memset(msg, 0, sizeof(DB_EXC_MSG_SIZE));
		memset(reply, 0, sizeof(DB_EXC_MSG_SIZE));

		// wait to receive a message from the kernel
		r = mach_msg(msg, MACH_RCV_MSG, DB_EXC_MSG_SIZE, DB_EXC_MSG_SIZE, exception_port, 0, MACH_PORT_NULL);
		
		if (r != MACH_MSG_SUCCESS) {
#if DEBUG
            NSLog(@"machExceptionHandlerThread: mach_msg %s", mach_error_string(r));
#endif
			break;
		}
		
		// dispatch the message to exc_server and get a reply back
		// this uses some scary mach magic to call our three functions below
		// catch_exception_raise, catch_exception_raise_state,
		// catch_exception_raise_state_identity
        if (!exc_server(msg, reply)) {
#if DEBUG
            NSLog(@"machExceptionHandlerThread: exc_server");
#endif
			break;
        }

		// reply to the exception message
		r = mach_msg (reply, MACH_SEND_MSG, reply->msgh_size, 0, msg->msgh_local_port, 0, MACH_PORT_NULL);

		// free the messages
		free(msg);
		free(reply);
	}
	
	// if we're out of the for loop something is wrong, so let's complain
#if DEBUG
	NSLog(@"machExceptionHandlerThread: ended");
#endif
}

#define MACH_CHECK_ERROR(name,ret) \
if (ret != KERN_SUCCESS) { \
    mach_error(#name, ret); \
    exit(1); \
}

/*
 * From: http://www.wodeveloper.com/omniLists/macosx-dev/2000/June/msg00137.html
 *
 */
static kern_return_t forward_exception(mach_port_t thread_port,
                                       mach_port_t task_port,
                                       exception_type_t exception_type,
                                       exception_data_t exception_data,
                                       mach_msg_type_number_t data_count,
                                       DBExceptionPorts *oldExceptionPorts)
{
    kern_return_t kret;
    unsigned int portIndex;
	
    mach_port_t port;
    exception_behavior_t behavior;
    thread_state_flavor_t flavor;
	
    thread_state_data_t thread_state;
    mach_msg_type_number_t thread_state_count;
	
    for (portIndex = 0; portIndex < oldExceptionPorts->maskCount; portIndex++) {
        if (oldExceptionPorts->masks[portIndex] & (1 << exception_type)) {
            // This handler wants the exception
            break;
        }
    }
		
    if (portIndex >= oldExceptionPorts->maskCount) {
#if DEBUG
        NSLog(@"No handler for exception_type = %d.  Not fowarding", exception_type);
#endif
        return KERN_FAILURE;
    }
	
    port = oldExceptionPorts->handlers[portIndex];
    behavior = oldExceptionPorts->behaviors[portIndex];
    flavor = oldExceptionPorts->flavors[portIndex];

#if DEBUG
    NSLog(@"forwarding exception, port = 0x%x, behaviour = %d, flavor = %d", port, behavior, flavor);
#endif
	
    if (behavior != EXCEPTION_DEFAULT) {
        thread_state_count = THREAD_STATE_MAX;
        kret = thread_get_state (thread_port, flavor, thread_state,  
								 &thread_state_count);
        MACH_CHECK_ERROR (thread_get_state, kret);
    }
	
    switch (behavior) {
		
        case EXCEPTION_DEFAULT:
#if DEBUG
            NSLog(@"forwarding to exception_raise");
#endif
            kret = exception_raise
                (port, thread_port, task_port, exception_type,  
				 exception_data, data_count);
            MACH_CHECK_ERROR (exception_raise, kret);
            break;
			
        case EXCEPTION_STATE:
 #if DEBUG
			NSLog(@"forwarding to exception_raise_state");
 #endif
			kret = exception_raise_state
                (port, exception_type, exception_data, data_count, &flavor,
                 thread_state, thread_state_count, thread_state,  
				 &thread_state_count);
            MACH_CHECK_ERROR (exception_raise_state, kret);
            break;
			
        case EXCEPTION_STATE_IDENTITY:
#if DEBUG
			NSLog(@"forwarding to exception_raise_state_identity");
#endif
            kret = exception_raise_state_identity
                (port, thread_port, task_port, exception_type,  
				 exception_data,  data_count,
                 &flavor, thread_state, thread_state_count, thread_state,   
				 &thread_state_count);
            MACH_CHECK_ERROR (exception_raise_state_identity, kret);
            break;
			
        default:
#if DEBUG
            NSLog(@"forward_exception got unknown behavior");
#endif
            break;
    }
	
    if (behavior != EXCEPTION_DEFAULT) {
        kret = thread_set_state (thread_port, flavor, thread_state,  
								 thread_state_count);
        MACH_CHECK_ERROR (thread_set_state, kret);
    }
	
    return KERN_SUCCESS;
}

kern_return_t catch_exception_raise(mach_port_t exception_port,
									mach_port_t thread,
									mach_port_t task,
									exception_type_t exception,
									exception_data_t code,
									mach_msg_type_number_t codeCount)
{
    kern_return_t krc;	
    mach_msg_type_number_t thread_state_count;
	thread_state_count = THREAD_STATE_MAX;

	void *ip = 0;
	
#ifdef __POWERPC__
	ppc_thread_state_t ppc_thread_state;
	krc = thread_get_state(thread, MACHINE_THREAD_STATE, &ppc_thread_state, &thread_state_count);
				
	ip = (void *)ppc_thread_state.srr0;
#elif __i386__
	i386_thread_state_t i386_thread_state;
	krc = thread_get_state(thread, MACHINE_THREAD_STATE, &i386_thread_state, &thread_state_count);
	
	ip = (void *)i386_thread_state.eip;
#else
#error NOT IMPLEMENTED, SUCKA.
#endif

	// Log the exception _here_ if you want both exceptions from mono & native code
	
	// see if we're in mono-land
	MonoJitInfo *ji = mono_jit_info_table_find(mono_domain_get(), ip);
	
	if (ji) {
#if DEBUG
		NSLog(@"machExceptionThread: NullReferenceException sent back to Mono", ji);
#endif

		// returning KERN_FAILURE causes the exception to be tossed as a signal
		return KERN_FAILURE;
	}
	
	// Log the exception _here_ if you want only exceptions in native code
	
	// otherwise, forward the exception
    krc =  forward_exception(thread, task, exception, code, codeCount, oldHandlerData);
    return krc;
}

kern_return_t catch_exception_raise_state(mach_port_t exception_port,
										  exception_type_t exception,
										  exception_data_t code,
										  mach_msg_type_number_t codeCnt,
										  int *flavor,
										  thread_state_t old_state,
										  mach_msg_type_number_t old_stateCnt,
										  thread_state_t new_state,
										  mach_msg_type_number_t *new_stateCnt)
{
    kern_return_t krc;

	// don't have thread or task? uh...
	// krc =  forward_exception(thread, task, exception, code, codeCnt, oldHandlerData);
	krc = KERN_FAILURE;
    return krc;
}

kern_return_t catch_exception_raise_state_identity(mach_port_t exception_port, mach_port_t thread,
												   mach_port_t task,
												   exception_type_t exception,
												   exception_data_t code,
												   mach_msg_type_number_t codeCnt,
												   int *flavor,
												   thread_state_t old_state,
												   mach_msg_type_number_t old_stateCnt,
												   thread_state_t new_state,
												   mach_msg_type_number_t *new_stateCnt)
{
    kern_return_t krc;

    krc =  forward_exception(thread, task, exception, code, codeCnt, oldHandlerData);
    return krc;
}

@end
