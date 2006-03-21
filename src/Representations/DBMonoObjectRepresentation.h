//
//  DBMonoObjectRepresentation.h
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

#import <Foundation/Foundation.h>

#import "DBUtility.h"

@interface DBMonoObjectRepresentation : NSObject <NSCopying> {
	
	@protected
	MonoObject *_obj;
	
	@private
	guint32 _mono_gchandle;
}

//subclasses should override this
+ (MonoClass *)monoClass;

+ (id)representationWithMonoObject:(MonoObject *)obj;
+ (id)representationWithNumArgs:(int)numArgs, ...;

- (id)initWithMonoObject:(MonoObject *)obj;
- (id)initWithSignature:(const char *)constructorSignature withNumArgs:(int)numArgs, ...;

- (MonoClass *)monoClass;
- (MonoObject *)monoObject;

//Method Invocation
- (MonoObject *)invokeMethod:(const char *)methodName withNumArgs:(int)numArgs varArgList:(va_list)va_args;
- (MonoObject *)invokeMethod:(const char *)methodName withNumArgs:(int)numArgs, ...;

//Indexer Access
- (MonoObject *)monoObjectForIndexObject:(void *)indexObject;
- (void)setMonoObject:(MonoObject *)valueObject forIndexObject:(void *)indexObject;

//Field Access
- (void)getField:(const char *)fieldName valueObject:(void *)valueObject;
- (void)setField:(const char *)fieldName valueObject:(void *)valueObject;

//Property Access
- (MonoObject *)getProperty:(const char *)propertyName;
- (void)setProperty:(const char *)propertyName valueObject:(MonoObject *)valueObject;

@end
