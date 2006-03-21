//
//  DBStringCategory.m
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

#import "DBStringCategory.h"

#import "DBWrappers.h"

@implementation NSString (Dumbarton)

+ (id)stringWithMonoString:(MonoString *)monoString {
	DBWrappedString *wrappedString = [[DBWrappedString alloc] initWithMonoString:monoString];
	
	return([wrappedString autorelease]);

	/*
	if(monoString == NULL) return(nil);
	
	int32_t gcHandle = mono_gchandle_new((MonoObject *)monoString,YES);
	NSString *string = [NSString stringWithCharacters:mono_string_chars(monoString) length:mono_string_length(monoString)];
	mono_gchandle_free(gcHandle);

	return(string);
	 */
}

- (id)initWithMonoString:(MonoString *)monoString {
	if(self) {
		[self release];
		self = [[DBWrappedString alloc] initWithMonoString:monoString];
	}
	
	return(self);

	/*
	if(monoString == NULL) {
		[self release];
		self = nil;
	} else {
		int32_t gcHandle = mono_gchandle_new((MonoObject *)monoString, YES);
		self = [self initWithCharacters:mono_string_chars(monoString) length:mono_string_length(monoString)];
		mono_gchandle_free(gcHandle);
	}
	
	return(self);
	 */
}

- (MonoString *)monoString {
	MonoString *monoString = mono_string_new_size(mono_domain_get(), [self length]);

	int32_t gcHandle = mono_gchandle_new((MonoObject *)monoString, YES);
	[self getCharacters:mono_string_chars(monoString)];
	mono_gchandle_free(gcHandle);
	
	return(monoString);	
}

@end
