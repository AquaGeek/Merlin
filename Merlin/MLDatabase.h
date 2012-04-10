//
//  MLDatabase.h
//  Merlin
//
//  Created by Tyler Stromberg on 3/11/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

@interface MLDatabase : NSObject

@property (nonatomic, readonly) sqlite3 *database;

+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase;
- (id)initWithPath:(NSString *)pathToDatabase;

@end
