//
//  DBMonoObjectRepresentation.m
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

#import "DBMonoObjectRepresentation.h"

#import "DBStringCategory.h"

@implementation DBMonoObjectRepresentation

//this needs to be overridden if you want initWithNumArgs or initWithVarArgs to return anyting but nil.
+ (MonoClass *)monoClass {
	@throw([NSException exceptionWithName:@"No monoClass override" reason:@"This class does not override +[DBMonoObjectRepresentation monoClass]" userInfo:nil]);
}

+ (id)representationWithMonoObject:(MonoObject *)obj {
	DBMonoObjectRepresentation *rep = [[[self class] alloc] initWithMonoObject:obj];
	return([rep autorelease]);
}

+ (id)representationWithNumArgs:(int)numArgs, ... {
	Class class = [self class];
	MonoClass *monoClass = [class monoClass];
	if(monoClass == NULL) return(nil);
	
	va_list va_args;
	va_start(va_args, numArgs);
	
	MonoObject *newObject = DBMonoObjectVarArgsConstruct(monoClass, numArgs, va_args);
	DBMonoObjectRepresentation *rep = [class representationWithMonoObject:newObject];
	
	va_end(va_args);
	
	return(rep);
}

- (id)init
{
	return([self initWithSignature:"" withNumArgs:0]);
}

- (id)initWithMonoObject:(MonoObject *)obj {
	self = [super init];
	if(self) {
		_obj = obj;
		
		if(obj != NULL) {
			_mono_gchandle = mono_gchandle_new(obj, FALSE);
		} else {
			[self release];
			self = nil;
		}
	}
	
	return self;
}

- (id)initWithSignature:(const char *)signature withNumArgs:(int)numArgs, ... {
	MonoClass *monoClass = [[self class] monoClass];
	if(monoClass == NULL) return(nil);
	
	va_list va_args;
	va_start(va_args, numArgs);
	
	MonoObject *newObject = DBMonoObjectSignatureVarArgsConstruct(monoClass, signature, numArgs, va_args);
	self = [self initWithMonoObject:newObject];
	
	va_end(va_args);
	
	return(self);
}

- (void)dealloc {
	if(_obj != NULL) {
		mono_gchandle_free(_mono_gchandle);
	}
	
	[super dealloc];
}

- (NSString *)description {
	MonoString *monoString = (MonoString *)[self invokeMethod:"System.Object:ToString()" withNumArgs:0];
	
	return([NSString stringWithMonoString:monoString]);
}

#pragma mark NSCopying Protocol

- (id)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] allocWithZone:zone] initWithMonoObject:_obj];
	
	return(copy);
}

#pragma mark -

- (MonoClass *)monoClass {
	return mono_object_get_class(_obj);
}

- (MonoObject *)monoObject {
	return _obj;
}

#pragma mark Method Invocation

- (MonoObject *)invokeMethod:(const char *)methodName withNumArgs:(int)numArgs varArgList:(va_list)va_args {
	return(DBMonoObjectInvoke(_obj, methodName, numArgs, va_args));
}

- (MonoObject *)invokeMethod:(const char *)methodName withNumArgs:(int)numArgs, ... {
	va_list va_args;
	va_start(va_args, numArgs);
	
	MonoObject *ret = DBMonoObjectInvoke(_obj, methodName, numArgs, va_args);
	
	va_end(va_args);
	
	return ret;
}

#pragma mark Indexer Access

- (MonoObject *)monoObjectForIndexObject:(void *)indexObject {
	return(DBMonoObjectGetIndexedObject(_obj, indexObject));
}

- (void)setMonoObject:(MonoObject *)valueObject forIndexObject:(void *)indexObject {
	DBMonoObjectSetIndexedObject(_obj, indexObject, valueObject);
}

#pragma mark Field Access

- (void)getField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoObjectGetField(_obj, fieldName, valueObject);
}

- (void)setField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoObjectSetField(_obj, fieldName, valueObject);
}

#pragma mark Property Access

- (MonoObject *)getProperty:(const char *)propertyName {
	return(DBMonoObjectGetProperty(_obj, propertyName));
}

- (void)setProperty:(const char *)propertyName valueObject:(MonoObject *)valueObject {
	DBMonoObjectSetProperty(_obj, propertyName, valueObject);
}


@end
