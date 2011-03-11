//
//  MLBase.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "MLBase.h"

#import <objc/runtime.h>

#import "MLColumn.h"

@interface MLBase()

+ (void)evaluateQuery:(NSString *)queryString withBlock:(void (^)(MLBase *obj))block;
+ (void)injectColumnProperties:(NSArray *)columns;

@end


#pragma mark -

@implementation MLBase

#pragma mark Config/setup

// TODO: Attach hash to class to map class names to databases?
static sqlite3 *database = NULL;

+ (BOOL)setDatabasePath:(NSString *)pathToDatabase
{
    static NSMutableDictionary *databaseMapping = nil;
    
    if (databaseMapping == nil)
    {
        databaseMapping = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    NSString *className = NSStringFromClass(self);
    NSString *databasePath = [databaseMapping objectForKey:className];
    
    if (![pathToDatabase isEqualToString:databasePath])
    {
        // Clear out the old path and database
        [databasePath release];
        databasePath = nil;
        
        if (database != NULL)
        {
            sqlite3_close(database);
            database = NULL;
        }
        
        // Init database
        if(sqlite3_open([pathToDatabase UTF8String], &database) != SQLITE_OK)
        {
            NSLog(@"Failed to open database at '%@'", pathToDatabase);
            return NO;
        }
        
        databasePath = [pathToDatabase copy];
        return YES;
    }
    
    // Harmless no-op if database path hasn't changed
    return YES;
}

+ (NSString *)tableName
{
    NSString *className = NSStringFromClass([self class]);
    return [className stringByAppendingString:@"s"];
}

// TODO: Better way to keep track of columns per class?
+ (NSArray *)columns
{
    static NSMutableDictionary *columnsMapping = nil;
    
    if (columnsMapping == nil)
    {
        columnsMapping = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    
    // Check if we've already cached the columns for this table
    NSArray *cachedColumns = [columnsMapping valueForKey:[self tableName]];
    if (cachedColumns != nil)
    {
        return cachedColumns;
    }
    
    NSMutableArray *columns = [NSMutableArray array];
    
    NSString *schemaQuery = [NSString stringWithFormat:@"PRAGMA table_info(\"%@\")", [self tableName]];
    
    sqlite3_stmt *queryStatement = NULL;
    if (sqlite3_prepare(database, [schemaQuery UTF8String], -1, &queryStatement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(queryStatement) == SQLITE_ROW)
        {
            NSLog(@"We found a column!");
            
            // Extract the column's metadata
            // cid|name|type|notnull|dflt_value|pk
            NSInteger columnId = sqlite3_column_int(queryStatement, 0);
            NSString *name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryStatement, 1)];
            
            // TODO: There's got to be a better way to do this
            NSString *typeStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryStatement, 2)];
            SQLiteColumnType type = kSQLiteColumnTypeNull;
            if ([typeStr isEqualToString:@"INTEGER"])
                type = kSQLiteColumnTypeInteger;
            else if ([typeStr isEqualToString:@"FLOAT"])
                type = kSQLiteColumnTypeFloat;
            else if ([typeStr isEqualToString:@"TEXT"])
                type = kSQLiteColumnTypeText;
            else if ([typeStr isEqualToString:@"BLOB"])
                type = kSQLiteColumnTypeBlob;
            
            BOOL allowsNull = !sqlite3_column_int(queryStatement, 3);
            BOOL isPrimaryKey = sqlite3_column_int(queryStatement, 5);
            
            MLColumn *newColumn = [MLColumn columnWithId:columnId
                                                    name:name
                                                    type:type
                                              allowsNull:(allowsNull && !isPrimaryKey)];
            [columns addObject:newColumn];
        }
        
        // Add properties for each fetched column
        [self injectColumnProperties:columns];
        
        sqlite3_finalize(queryStatement);
    }
    
    // Cache the columns
    [columnsMapping setObject:columns forKey:[self tableName]];
    
    return columns;
}

id getSQLiteAttributeIMP(MLBase *self, SEL _cmd)
{
    NSString *getterName = NSStringFromSelector(_cmd);
    return [self->attributes valueForKey:getterName];
}

void setSQLiteAttributeIMP(MLBase *self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    
    // Remove the 'set' in front and downcase the first letter
    NSRange setRange = [setterName rangeOfString:@"set"];
    NSString *keyName = nil;
    
    if (setRange.location != NSNotFound)
    {
        keyName = [[[setterName substringWithRange:NSMakeRange(NSMaxRange(setRange), 1)] lowercaseString]
                   stringByAppendingString:[setterName substringFromIndex:NSMaxRange(setRange) + 1]];
    }
    else
    {
        keyName = setterName;
    }
    
    // Remove the trailing ':'
    if ([keyName rangeOfString:@":"].location != NSNotFound)
    {
        keyName = [keyName stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    
    [self->attributes setValue:newValue forKey:keyName];
}

+ (void)injectColumnProperties:(NSArray *)columns
{
    for (MLColumn *column in columns)
    {
        NSString *getterName = column.name;
        class_addMethod(self, NSSelectorFromString(getterName), (IMP)&getSQLiteAttributeIMP, "@@:");
        
        NSString *capitalizedColumnName = [[[column.name substringToIndex:1] uppercaseString] stringByAppendingString:[column.name substringFromIndex:1]];
        NSString *setterName = [NSString stringWithFormat:@"set%@:", capitalizedColumnName];
        class_addMethod(self, NSSelectorFromString(setterName), (IMP)&setSQLiteAttributeIMP, "v@:@");
    }
}


#pragma mark - Finders

+ (MLBase *)first
{
    __block MLBase *fetchedObject = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM \"%@\" ORDER BY id ASC LIMIT 1", [self tableName]];
    
    [self evaluateQuery:query withBlock:^(MLBase *matchingObject) {
        fetchedObject = matchingObject;
    }];
    
    return [fetchedObject autorelease];
}

+ (MLBase *)last
{
    __block MLBase *fetchedObject = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM '%@' ORDER BY id DESC LIMIT 1", [self tableName]];
    
    [self evaluateQuery:query withBlock:^(MLBase *matchingObject) {
        fetchedObject = matchingObject;
    }];
    
    return fetchedObject;
}

+ (NSArray *)all
{
    NSMutableArray *fetchedObjects = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM '%@'", [self tableName]];
    
    [self evaluateQuery:query withBlock:^(MLBase *matchingObject) {
        [fetchedObjects addObject:matchingObject];
    }];
    
    return fetchedObjects;
}

+ (NSArray *)findWithCriteria:(NSString *)criteria
{
    NSMutableArray *matchingObjects = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE %@", [self tableName], criteria];
    
    [self evaluateQuery:query withBlock:^(MLBase *matchingObject) {
        [matchingObjects addObject:matchingObject];
    }];
    
    return matchingObjects;
}

+ (void)evaluateQuery:(NSString *)queryString withBlock:(void (^)(MLBase *obj))block
{
    if (block == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"'block' cannot be nil"];
    }
    
    sqlite3_stmt *queryStatement = NULL;
    if (sqlite3_prepare_v2(database, [queryString UTF8String], -1, &queryStatement, NULL) == SQLITE_OK)
    {
        int i = 0;
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        
        while (sqlite3_step(queryStatement) == SQLITE_ROW)
        {
            [attributes removeAllObjects];
            
            for (MLColumn *column in [self columns])
            {
                id value = nil;
                int byteCount = 0;
                
                switch (column.type) {
                    case kSQLiteColumnTypeInteger:
                        value = [NSNumber numberWithInt:sqlite3_column_int(queryStatement, column.columnId)];
                        break;
                    case kSQLiteColumnTypeText:
                        value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryStatement, column.columnId)];
                        break;
                    case kSQLiteColumnTypeNull:
                        value = [NSNull null];
                        break;
                    case kSQLiteColumnTypeFloat:
                        value = [NSNumber numberWithDouble:sqlite3_column_double(queryStatement, column.columnId)];
                        break;
                    case kSQLiteColumnTypeBlob:
                        byteCount = sqlite3_column_bytes(queryStatement, column.columnId);
                        value = [NSData dataWithBytes:sqlite3_column_blob(queryStatement, column.columnId) length:byteCount];
                    default:
                        break;
                }
                
                if (value != nil)
                {
                    [attributes setObject:value forKey:column.name];
                }
            }
            
            MLBase *matchingObject = [[self alloc] initWithAttributes:attributes];
            
            block(matchingObject);
            
            [matchingObject release];
            
            i++;
        }
    }
}


#pragma mark -

- (id)initWithAttributes:(NSDictionary *)newAttributes
{
    self = [super init];
    
    if (self)
    {
        attributes = [[NSMutableDictionary alloc] initWithDictionary:newAttributes];
    }
    
    return self;
}

- (void)dealloc
{
    [attributes release];
    
    [super dealloc];
}

@end
