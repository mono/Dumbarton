//
//  DBIList.m
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

#import "DBIList.h"
#import "DBMonoEnvironment.h"

@implementation DBIList

+ (id)listWithMonoObject:(MonoObject *)monoObject withRepresentationClass:(Class)representationClass {
	DBIList *list = [[[self class] alloc] initWithMonoObject:monoObject withRepresentationClass:representationClass];
	return([list autorelease]);
}

- (id)initWithMonoObject:(MonoObject *)monoObject withRepresentationClass:(Class)representationClass {
	self = [super initWithMonoObject:monoObject];
	if(self) {
		_representationClass = representationClass;
	}
	return(self);
}

- (int)addMonoObject:(MonoObject *)monoObject {
	MonoObject *retBox = [self invokeMethod:"Add(object)" withNumArgs:1, monoObject];
	return(DB_UNBOX_INT32(retBox));
}

//
//Indexer Access
//
- (MonoObject *)monoObjectAtIndex:(int)index {
	return([self monoObjectForIndexObject:&index]);
}

- (void)setMonoObject:(MonoObject *)monoObject forIndex:(int)index {
	[self setMonoObject:monoObject forIndexObject:&index];
}

//
//Wrapped Indexer Access
//
- (id)objectAtIndex:(int)index {
	if(_representationClass != NULL) {
		id retID = nil;
		
		if(_representationClass != nil) {
			MonoObject *monoObject = [self monoObjectForIndexObject:&index];
			retID = [_representationClass representationWithMonoObject:monoObject];
		}
		
		return(retID);
	} else {
		@throw([NSException exceptionWithName:@"No Representation Class" reason:@"objectAtIndex called on a DBIList without specified RepresentationClass" userInfo:nil]);
	}
}

- (void)setObjectAtIndex:(int)index object:(DBMonoObjectRepresentation *)object {
	[self setMonoObject:[object monoObject] forIndexObject:&index];
}


//
//.NET IList wrapperstuff
//

- (int32_t)count {
	MonoObject *retval = [self getProperty:"Count"];
	return(DB_UNBOX_INT32(retval));
}

- (void)clear {
	[self invokeMethod:"Clear" withNumArgs:0];
}

- (BOOL)containsMonoObject:(MonoObject *)monoObject {
	MonoObject *retBox = [self invokeMethod:"Contains(object)" withNumArgs:1, monoObject];
	return(DB_UNBOX_BOOLEAN(retBox));
}

- (int)indexOfMonoObject:(MonoObject *)monoObject {
	MonoObject *retBox = [self invokeMethod:"IndexOf(object)" withNumArgs:1, monoObject];
	return(DB_UNBOX_INT32(retBox));
}

- (void)insertMonoObject:(MonoObject *)monoObject atIndex:(int)index {
	[self invokeMethod:"Insert(int,object)" withNumArgs:2, &index, monoObject];
}

- (void)removeMonoObject:(MonoObject *)monoObject {
	[self invokeMethod:"Remove(object)" withNumArgs:1, monoObject];
}

- (void)removeAtIndex:(int32_t)index {
	[self invokeMethod:"RemoveAt(int)" withNumArgs:1, &index];
}

//convenience methods
- (int64_t)int64AtIndex:(int)index {
	MonoObject *monoObject = [self monoObjectForIndexObject:&index];
	if(mono_object_get_class(monoObject) != mono_get_int64_class())
		@throw([NSException exceptionWithName:@"Type Mismatch" reason:@"MonoObject is not int64" userInfo:nil]);
	return(DB_UNBOX_INT64(monoObject));
}

- (void)setInt64AtIndex:(int)index value:(int64_t)value {
	MonoObject *boxedValue = DB_BOX_INT64(value);
	[self setMonoObject:boxedValue forIndexObject:&index];
}

- (int32_t)int32AtIndex:(int)index {
	MonoObject *monoObject = [self monoObjectForIndexObject:&index];
	if(mono_object_get_class(monoObject) != mono_get_int32_class())
	   @throw([NSException exceptionWithName:@"Type Mismatch" reason:@"MonoObject is not int32" userInfo:nil]);
	return(DB_UNBOX_INT32(monoObject));
}

- (void)setInt32AtIndex:(int)index value:(int32_t)value {
	MonoObject *boxedValue = DB_BOX_INT32(value);
	[self setMonoObject:boxedValue forIndexObject:&index];
}

@end
