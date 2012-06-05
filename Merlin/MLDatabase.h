//
//  MLDatabase.h
//  Merlin
//
//  Created by Tyler Stromberg on 3/11/11.
//  Copyright 2011-2012 AKQA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

@interface MLDatabase : NSObject

@property (nonatomic, readonly) sqlite3 *database;

+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase;
+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase reuseConnection:(BOOL)reuseConnection;
- (id)initWithPath:(NSString *)pathToDatabase;
- (id)initWithPath:(NSString *)pathToDatabase reuseConnection:(BOOL)reuseConnection;

+ (NSString *)escapeString:(NSString *)string;
- (BOOL)evaluateQuery:(NSString *)queryString withBlock:(void (^)(NSDictionary *attributes))block;

@end
