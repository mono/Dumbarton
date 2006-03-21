
//  Dumbarton
//  DBSize.m
//  Created by Dustin Mierau on 2/27/06.
//  Copyright 2006 imeem, Inc. All rights reserved.

#import "DBSize.h"
#import "DBMonoEnvironment.h"
#import "DBCategories.h"

static MonoClass* sMonoClass = NULL;

@implementation DBSize

+ (MonoClass*)monoClass
{
	if( !sMonoClass )
		sMonoClass = [DBMonoEnvironment corlibMonoClassWithName:"System.Image.Size"];
	
	return sMonoClass;
}

#pragma mark - 

+ (DBSize*)sizeWithMonoObject:(MonoObject*)inMonoObject
{
	return [[[DBSize alloc] initWithMonoObject:inMonoObject] autorelease];
}

+ (NSSize)convertToNSSize:(MonoObject*)inMonoObject
{
	NSSize	size;
	DBSize*	monoSize = [[DBSize alloc] initWithMonoObject:inMonoObject];
	
	size.width = (float)[monoSize width];
	size.height = (float)[monoSize height];
	
	[monoSize release];
	
	return size;
}

#pragma mark -

- (int)width
{
	MonoObject* width = [self getProperty:"Width"];
	return DB_UNBOX_INT32( width );
}

- (int)height
{
	MonoObject* height = [self getProperty:"Height"];
	return DB_UNBOX_INT32( height );
}

#pragma mark -

- (BOOL)isEmpty
{
	MonoObject* isempty = [self getProperty:"IsEmpty"];
	return DB_UNBOX_BOOLEAN( isempty );
}

@end
