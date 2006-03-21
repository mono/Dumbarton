//
//  DBWrappedData.m
//  Dumbarton
//
//  Created by Allan Hsu on 1/11/06.
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

#import "DBWrappedData.h"

@implementation DBWrappedData

- (id)initWithMonoArray:(MonoArray *)monoArray {
	_monoArray = monoArray;
	if(monoArray == NULL) {
		[self release];
		self = nil;
	} else {
		_gcHandle = mono_gchandle_new((MonoObject *)monoArray, YES);
		
		MonoClass *arrayClass = mono_object_get_class((MonoObject *)monoArray);
		_dataBytes = monoArray->vector;
		_dataLength = mono_array_length(monoArray) * mono_array_element_size(arrayClass);
	}
	
	return(self);
}

- (void)dealloc {
	if(_monoArray != NULL) {
		mono_gchandle_free(_gcHandle);
	}
	
	[super dealloc];
}

- (MonoArray *)monoArray {
	return(_monoArray);
}

#pragma mark -
#pragma mark Primitive Method Overrides

- (const void *)bytes {
	return(_dataBytes);
}

- (unsigned)length {
	return(_dataLength);
}

#pragma mark -
#pragma mark Other Overrides

- (id)copy {
	DBWrappedData *copy = [[DBWrappedData alloc] initWithMonoArray:_monoArray];
	
	return(copy);
}

- (id)copyWithZone:(NSZone *)zone {
	DBWrappedData *copy = [[DBWrappedData allocWithZone:zone] initWithMonoArray:_monoArray];
	
	return(copy);
}

- (void)getBytes:(void *)buffer {
	memcpy(buffer, _dataBytes, _dataLength);
}

- (void)getBytes:(void *)buffer length:(unsigned)length {
	memcpy(buffer, _dataBytes, MIN(_dataLength, length));
}

- (void)getBytes:(void *)buffer range:(NSRange)range {
	if(range.location + range.length > _dataLength)
		@throw([NSException exceptionWithName:NSRangeException reason:@"Byte range beyond data bounds." userInfo:nil]);
	
	memcpy(buffer, _dataBytes + range.location, range.length);
}

@end
