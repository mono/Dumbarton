//
//  DBWrappedString.m
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

#import "DBWrappedString.h"

@implementation DBWrappedString

- (id)initWithMonoString:(MonoString *)monoString {
	self = [super init];
	
	if(self) {
		_monoString = monoString;
		if(monoString == NULL) {
			[self release];
			self = nil;
		} else {
			_gcHandle = mono_gchandle_new((MonoObject *)monoString, NO);
			_stringLength = mono_string_length(monoString);
		}
	}
	
	return(self);
}

- (void)dealloc {
	if(_monoString != NULL) {
		mono_gchandle_free(_gcHandle);
	}
	
	[super dealloc];
}

- (MonoString *)monoString {
	return(_monoString);
}

#pragma mark -
#pragma mark Primitive Method Overrides

- (unsigned int)length {
	return(_stringLength);
}

- (unichar)characterAtIndex:(unsigned)index {
	if(index >= _stringLength)
		@throw([NSException exceptionWithName:NSRangeException reason:@"Character index beyond string bounds." userInfo:nil]);

	guint32 pinHandle = mono_gchandle_new((MonoObject *)_monoString, YES);
	unichar *stringCharacters = mono_string_chars(_monoString);
	unichar character = stringCharacters[index];
	mono_gchandle_free(pinHandle);
	
	return(character);
}

#pragma mark -
#pragma mark Other Overrides

- (id)copy {
	DBWrappedString *copy = [[DBWrappedString alloc] initWithMonoString:_monoString];
	
	return(copy);
}

- (id)copyWithZone:(NSZone *)zone {
	DBWrappedString *copy = [[DBWrappedString allocWithZone:zone] initWithMonoString:_monoString];
	
	return(copy);
}

- (void)getCharacters:(unichar *)buffer {
	guint32 pinHandle = mono_gchandle_new((MonoObject *)_monoString, YES);
	unichar *stringCharacters = mono_string_chars(_monoString);
	memcpy(buffer, stringCharacters, (_stringLength * sizeof(unichar)));
	mono_gchandle_free(pinHandle);
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
	if(range.location + range.length > _stringLength)
		@throw([NSException exceptionWithName:NSRangeException reason:@"Character range beyond string bounds." userInfo:nil]);
	
	guint32 pinHandle = mono_gchandle_new((MonoObject *)_monoString, YES);
	unichar *stringCharacters = mono_string_chars(_monoString);
	memcpy(buffer, stringCharacters + range.location, (range.length * sizeof(unichar)));
	mono_gchandle_free(pinHandle);
}

@end
