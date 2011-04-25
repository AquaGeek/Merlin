//
//  MLDatabase.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/11/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "MLDatabase.h"

@implementation MLDatabase

@synthesize database;

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
        databasePath = [pathToDatabase copy];
        
        if(sqlite3_open([pathToDatabase UTF8String], &database) != SQLITE_OK)
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
    if (database != NULL)
    {
        sqlite3_close(database);
    }
    
    [super dealloc];
}

@end
