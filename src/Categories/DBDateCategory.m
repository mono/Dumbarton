//
//  DBDateCategory.m
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

#import "DBDateCategory.h"

//the number of .NET-equivalent ticks between 01-01-0001 and 01-01-2001
#define EPOCH_START_DIFFERENCE 631139040000000000LL
//there are 10^7 .NET datetime ticks per second.
#define NET_TICKS_PER_SECOND 10000000

static MonoClass *_dateTimeMonoClass;

@implementation NSDate (Dumbarton)

+ (id)dateWithMonoDateTime:(MonoObject *)monoDateTime {
	NSDate *date = [[self alloc] initWithMonoDateTime:monoDateTime];
	
	return([date autorelease]);
}

+ (id)dateWithMonoTicks:(int64_t)monoTicks {
	NSDate *date = [[self alloc] initWithMonoTicks:monoTicks];
	
	return([date autorelease]);
}

- (id)initWithMonoDateTime:(MonoObject *)monoDateTime {
	MonoObject *boxedTicks = DBMonoObjectGetProperty(monoDateTime, "Ticks");	
	int64_t ticks = DB_UNBOX_INT64(boxedTicks);
	NSTimeInterval interval = (NSTimeInterval)(ticks - EPOCH_START_DIFFERENCE) / NET_TICKS_PER_SECOND;
	self = [self initWithTimeIntervalSinceReferenceDate:interval];

	return(self);
}

- (id)initWithMonoTicks:(int64_t)monoTicks {
	NSTimeInterval interval = (NSTimeInterval)(monoTicks - EPOCH_START_DIFFERENCE) / NET_TICKS_PER_SECOND;
	self = [self initWithTimeIntervalSinceReferenceDate:interval];
	
	return(self);
}

- (MonoObject *)monoDateTime {
	if(_dateTimeMonoClass == NULL) {
		_dateTimeMonoClass = [DBMonoEnvironment corlibMonoClassWithName:"System.DateTime"];
	}
	int64_t ticks = ([self timeIntervalSinceReferenceDate] * NET_TICKS_PER_SECOND) + EPOCH_START_DIFFERENCE;
	MonoObject *monoDateTime = DBMonoObjectSignatureConstruct(_dateTimeMonoClass, "long", 1, &ticks);
	return(monoDateTime);
}

@end
