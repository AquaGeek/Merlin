//
//  MLDatabase.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/11/11.
//  Copyright 2011-2012 AKQA, Inc. All rights reserved.
//

#import "MLDatabase.h"

static NSMutableDictionary *connectionMap;

@implementation MLDatabase
{
@private
    NSString *_databasePath;
}

@synthesize database = _database;

+ (void)initialize
{
    if (self == [MLDatabase class])
    {
        connectionMap = [[NSMutableDictionary alloc] init];
    }
}

+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase
{
    return [self databaseWithPath:pathToDatabase reuseConnection:YES];
}

+ (MLDatabase *)databaseWithPath:(NSString *)pathToDatabase reuseConnection:(BOOL)reuseConnection
{
    MLDatabase *newDatabase = [[MLDatabase alloc] initWithPath:pathToDatabase];
    return newDatabase;
}

- (id)initWithPath:(NSString *)pathToDatabase
{
    return [self initWithPath:pathToDatabase reuseConnection:YES];
}

- (id)initWithPath:(NSString *)pathToDatabase reuseConnection:(BOOL)reuseConnection
{
    NSAssert(pathToDatabase != nil, @"pathToDatabase must not be nil");
    
    // See if we already have an open connection to the database at the given path.
    MLDatabase *db = [connectionMap objectForKey:pathToDatabase];
    
    if (reuseConnection && db != nil)
    {
        // If so, reuse it.
        self = db;
    }
    else if ((self = [super init]))
    {
        _databasePath = [pathToDatabase copy];
        
        if (sqlite3_open([pathToDatabase UTF8String], &_database) != SQLITE_OK)
        {
            NSLog(@"Failed to open database at '%@'", pathToDatabase);
            self = nil;
        }
        else if (db == nil)
        {
            // Only cache this connection if we don't already have one cached.
            [connectionMap setObject:self forKey:pathToDatabase];
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
}


#pragma mark -

+ (NSString *)escapeString:(NSString *)string
{
    static NSRegularExpression *quoteRegEx = nil;
    
    if (quoteRegEx == nil)
    {
        quoteRegEx = [[NSRegularExpression alloc] initWithPattern:@"'" options:0 error:NULL];
    }
    
    return [quoteRegEx stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"''"];
}

// This is a somewhat modified version of the sqlite3_exec implementation that uses blocks instead of
// callback functions and Objective-C objects instead of C primitives.
- (BOOL)evaluateQuery:(NSString *)queryString withBlock:(void (^)(NSDictionary *attributes))block
{
    sqlite3_stmt *preparedStatement = NULL;
    const char *sql = [queryString UTF8String];
    const char *remainingSQL = NULL;
    int rc = SQLITE_OK;
    
    while (rc == SQLITE_OK && sql[0])  // Loop until we run out of SQL or hit an error
    {
        int columnCount = 0;
        preparedStatement = NULL;
        
        rc = sqlite3_prepare_v2(self.database, sql, -1, &preparedStatement, &remainingSQL);
        
        if (rc != SQLITE_OK)
        {
            continue;
        }
        
        if (preparedStatement == NULL)
        {
            // This happens for a comment or whitespace
            sql = remainingSQL;
            continue;
        }
        
        columnCount = sqlite3_column_count(preparedStatement);
        
        NSMutableDictionary *attributes = nil;
        
        while (1)
        {
            // Try to step
            rc = sqlite3_step(preparedStatement);
            
            if (block && rc == SQLITE_ROW)
            {
                // Parse the resulting row into a dictionary and pass it to the callback block
                attributes = [NSMutableDictionary dictionaryWithCapacity:columnCount];
                for (int i = 0; i < columnCount; ++i)
                {
                    id value = nil;
                    NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(preparedStatement, i)];
                    
                    switch (sqlite3_column_type(preparedStatement, i))
                    {
                        case SQLITE_INTEGER:
                            value = [NSNumber numberWithLongLong:sqlite3_column_int64(preparedStatement, i)];
                            break;
                        case SQLITE_FLOAT:
                            value = [NSNumber numberWithDouble:sqlite3_column_double(preparedStatement, i)];
                            break;
                        case SQLITE_TEXT:
                            value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(preparedStatement, i)];
                            break;
                        case SQLITE_BLOB:
                        {
                            int byteCount = sqlite3_column_bytes(preparedStatement, i);
                            value = [NSData dataWithBytes:sqlite3_column_blob(preparedStatement, i) length:byteCount];
                            break;
                        }
                        case SQLITE_NULL:
                            value = [NSNull null];
                            break;
                        default:
                            // TODO: Raise exception
                            NSLog(@"Invalid SQLite type");
                            break;
                    }
                    
                    if (value != nil)
                    {
                        [attributes setObject:value forKey:columnName];
                    }
                }
                
                block(attributes);
                attributes = nil;
            }
            
            if (rc != SQLITE_ROW)
            {
                rc = sqlite3_finalize(preparedStatement);
                preparedStatement = NULL;
                
                if (rc != SQLITE_SCHEMA)
                {
                    sql = remainingSQL;
                }
                
                break;
            }
        }
    }
    
    if (preparedStatement != NULL)
    {
        sqlite3_finalize(preparedStatement);
    }
    
    if (rc != SQLITE_OK)
    {
        int errorCode = sqlite3_errcode(self.database);
        NSString *errorMessage = [NSString stringWithCString:sqlite3_errmsg(self.database) encoding:NSUTF8StringEncoding];
        
        NSLog(@"SQLite error %d: %@", errorCode, errorMessage);
    }
    
    return rc == SQLITE_OK;
}

@end
