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
}

- (id)initWithMonoArray:(MonoArray *)monoArray {
	if(self) {
		[self release];
		self = [[DBWrappedData alloc] initWithMonoArray:monoArray];
	}
	
	return(self);	
}

- (MonoArray *)monoArray {
	MonoArray *monoArray = mono_array_new(mono_domain_get(), mono_get_byte_class(), [self length]);
	[self getBytes:monoArray->vector];
	
	return(monoArray);
}

@end
