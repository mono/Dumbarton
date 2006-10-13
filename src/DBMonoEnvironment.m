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

static DBMonoEnvironment *_defaultEnvironment = nil;

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
		
	mono_jit_exec(_monoDomain, assembly, argCount, args);
	int retVal = mono_environment_exitcode_get();
	mono_jit_cleanup(_monoDomain);
	
	return(retVal);
}

//this thread is launched just to force cocoa into multithreaded mode.
- (void)nothingThread:(id)arg {
	//nothing actually goes on here.
}

@end
