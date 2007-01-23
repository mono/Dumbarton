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

#import "DBConvert.h"
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

#pragma mark -
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

#pragma mark -
#pragma mark Method Invocation

+ (MonoObject *)invokeClassMethod:(const char *)methodName withNumArgs:(int)numArgs varArgList:(va_list)va_args {
	return(DBMonoClassInvoke([[self class] monoClass], methodName, numArgs, va_args));
}

+ (MonoObject *)invokeClassMethod:(const char *)methodName withNumArgs:(int)numArgs, ... {
	va_list va_args;
	va_start(va_args, numArgs);
	
	MonoObject *ret = DBMonoClassInvoke([[self class] monoClass], methodName, numArgs, va_args);
	
	va_end(va_args);
	
	return ret;
}

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

#pragma mark -
#pragma mark Indexer Access

- (MonoObject *)monoObjectForIndexObject:(void *)indexObject {
	return(DBMonoObjectGetIndexedObject(_obj, indexObject));
}

- (void)setMonoObject:(MonoObject *)valueObject forIndexObject:(void *)indexObject {
	DBMonoObjectSetIndexedObject(_obj, indexObject, valueObject);
}

#pragma mark -
#pragma mark Field Access

+ (void)getClassField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoClassGetField([[self class] monoClass], fieldName, valueObject);
}

+ (void)setClassField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoClassSetField([[self class] monoClass], fieldName, valueObject);
}

- (void)getField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoObjectGetField(_obj, fieldName, valueObject);
}

- (void)setField:(const char *)fieldName valueObject:(void *)valueObject {
	DBMonoObjectSetField(_obj, fieldName, valueObject);
}

#pragma mark -
#pragma mark Property Access

+ (MonoObject *)getClassProperty:(const char *)propertyName {
	return(DBMonoClassGetProperty([[self class] monoClass], propertyName));
}

+ (void)setClassProperty:(const char *)propertyName valueObject:(MonoObject *)valueObject {
	DBMonoClassSetProperty([[self class] monoClass], propertyName, valueObject);
}

- (MonoObject *)getProperty:(const char *)propertyName {
	return(DBMonoObjectGetProperty(_obj, propertyName));
}

- (void)setProperty:(const char *)propertyName valueObject:(MonoObject *)valueObject {
	DBMonoObjectSetProperty(_obj, propertyName, valueObject);
}

#pragma mark -
#pragma mark System.IConvertible convenience

- (int8_t)int8Value {
	return([DBConvert convertMonoObjectToInt8:_obj]);
}

- (int16_t)int16Value {
	return([DBConvert convertMonoObjectToInt16:_obj]);
}

- (int32_t)int32Value {
	return([DBConvert convertMonoObjectToInt32:_obj]);
}

- (int64_t)int64Value {
	return([DBConvert convertMonoObjectToInt64:_obj]);
}

- (uint8_t)unsigned8Value {
	return([DBConvert convertMonoObjectToUInt8:_obj]);
}

- (uint16_t)unsigned16Value {
	return([DBConvert convertMonoObjectToUInt16:_obj]);
}

- (uint32_t)unsigned32Value {
	return([DBConvert convertMonoObjectToUInt32:_obj]);
}

- (uint64_t)unsigned64Value {
	return([DBConvert convertMonoObjectToUInt64:_obj]);
}

@end
