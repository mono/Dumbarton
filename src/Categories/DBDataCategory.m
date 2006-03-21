//
//  DBDataCategory.m
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

#import "DBDataCategory.h"

#import "DBWrappers.h"

@implementation NSData (Dumbarton)

+ (id)dataWithMonoArray:(MonoArray *)monoArray {

	DBWrappedData *wrappedData = [[DBWrappedData alloc] initWithMonoArray:monoArray];
	
	return([wrappedData autorelease]);
	
	/*
	NSData *newData = [[NSData alloc] initWithMonoArray:monoArray];
	return([newData autorelease]);
	 */
}

- (id)initWithMonoArray:(MonoArray *)monoArray {
	if(self) {
		[self release];
		self = [[DBWrappedData alloc] initWithMonoArray:monoArray];
	}
	
	return(self);
	
	/*
	if(monoArray != NULL) {
		int32_t gcHandle = mono_gchandle_new((MonoObject *)monoArray, YES);
		MonoClass *arrayClass = mono_object_get_class((MonoObject *)monoArray);
		self = [self initWithBytes:monoArray->vector length:mono_array_length(monoArray) * mono_array_element_size(arrayClass)];
		mono_gchandle_free(gcHandle);
	} else {
		[self release];
		return(nil);
	}
	
	return(self);
	 */
}

- (MonoArray *)monoArray {
	MonoArray *monoArray = mono_array_new(mono_domain_get(), mono_get_byte_class(), [self length]);
	[self getBytes:monoArray->vector];
	
	return(monoArray);
}

@end
