//
//  MLDatabase.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/11/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "MLDatabase.h"

@interface MLDatabase()
{
@private
    NSString *_databasePath;
}

@end


#pragma mark -

@implementation MLDatabase

@synthesize database = _database;

+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase
{
    MLDatabase *newDatabase = [[MLDatabase alloc] initWithPath:pathToDatabase];
    return [newDatabase autorelease];
}

- (id)initWithPath:(NSString *)pathToDatabase
{
    self = [super init];
    
    if (self != nil)
    {
        _databasePath = [pathToDatabase copy];
        
        if (sqlite3_open([pathToDatabase UTF8String], &_database) != SQLITE_OK)
        {
            NSLog(@"Failed to open database at '%@'", pathToDatabase);
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (_database != NULL)
    {
        sqlite3_close(_database);
    }
    
    [super dealloc];
}

@end
