//
//  DBEnum.m
//  Dumbarton
//
//  Created by Allan Hsu on 7/28/06.
//  Copyright 2006 imeem. All rights reserved.
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

#import "DBEnum.h"

#import "DBMonoClassRepresentation.h"
#import "DBMonoEnvironment.h"

static DBMonoClassRepresentation *_classRep = nil;

@implementation DBEnum

+ (void)initialize {
	if([self class] != [DBEnum class])
		return;
	
	_classRep = [[DBMonoClassRepresentation alloc] initWithMonoClassNamed:"System.Enum"];
}

+ (MonoReflectionType *)monoReflectionType {
	[NSException raise:@"No monoReflectionType override" format:@"This class does not override +[DBEnum monoReflectionType]"];
	
	return(nil);
}

#pragma mark -

+ (MonoObject *)monoEnumFromInt8:(int8_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,sbyte)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromInt16:(int16_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,short)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromInt32:(int32_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,int)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromInt64:(int64_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,long)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromUInt8:(uint8_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,byte)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromUInt16:(uint16_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,ushort)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromUInt32:(uint32_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,uint)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

+ (MonoObject *)monoEnumFromUInt64:(uint64_t)value {
	return([_classRep invokeMethod:"ToObject(System.Type,ulong)" withNumArgs:2, [[self class] monoReflectionType], &value]);
}

@end
