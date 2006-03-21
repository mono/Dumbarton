
//  Dumbarton
//  DBSize.h
//  Created by Dustin Mierau on 2/27/06
//  Copyright 2006 imeem, inc. All rights reserved.

#import "DBMonoObjectRepresentation.h"
#import "DBMonoIncludes.h"

@interface DBSize : DBMonoObjectRepresentation

+ (DBSize*)sizeWithMonoObject:(MonoObject*)inMonoObject;
+ (NSSize)convertToNSSize:(MonoObject*)inMonoObject;

- (int)width;
- (int)height;

- (BOOL)isEmpty;

@end