//
//  MLBase.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011-2012 AKQA, Inc. All rights reserved.
//

#import "MLBase.h"

#import <objc/runtime.h>
#import <sqlite3.h>

#import "MLColumn.h"
#import "MLDatabase.h"
#import "NSString+MerlinAdditions.h"

NSDictionary *sqlite3Step(sqlite3_stmt *aStatement);
id getSQLiteAttributeIMP(MLBase *self, SEL _cmd);
void setSQLiteAttributeIMP(MLBase *self, SEL _cmd, id newValue);

@interface MLBase()
{
@private
    NSMutableDictionary *_attributes;
    NSMutableDictionary *_changedAttributes;
}

+ (MLDatabase *)database;
+ (void)evaluateQuery:(NSString *)queryString withBlock:(void (^)(NSDictionary *attributes))block;
+ (void)fetchObjectsWithQuery:(NSString *)queryString withBlock:(void (^)(MLBase *obj))block;
+ (void)injectColumnProperties:(NSArray *)columns;

- (BOOL)createOrUpdate;
- (BOOL)update;
- (BOOL)create;

@end


#pragma mark -

@implementation MLBase

@dynamic id;
@synthesize newRecord = _newRecord;

#pragma mark Config/setup

// Hash to map class names to their respective databases
static NSMutableDictionary *databaseMapping = nil;
static BOOL returnNilForNull = NO;

+ (void)initialize
{
    if (self == [MLBase class])
    {
        databaseMapping = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
}

+ (void)setReturnsNilForNull:(BOOL)returnNil
{
    returnNilForNull = returnNil;
}

+ (void)setDatabase:(MLDatabase *)aDatabase
{
    NSString *className = NSStringFromClass(self);
    MLDatabase *mappedDatabaseForClass = [databaseMapping objectForKey:className];
    
    if (![mappedDatabaseForClass isEqual:aDatabase])
    {
        [databaseMapping setObject:aDatabase forKey:className];
        
        // Fetch our columns
        [self injectColumnProperties:[self columns]];
    }
}

// TODO: Support attaching to super's database
+ (MLDatabase *)database
{
    NSString *className = NSStringFromClass(self);
    return [databaseMapping objectForKey:className];
}

+ (NSString *)tableName
{
    NSString *className = [NSStringFromClass([self class]) lowerCamelCaseString];
    return [className stringByAppendingString:@"s"];
}

// TODO: Better way to keep track of columns per class?
+ (NSArray *)columns
{
    static NSMutableDictionary *columnMapping = nil;
    
    if (columnMapping == nil)
    {
        columnMapping = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    
    // Check if we've already cached the columns for this table
    NSArray *cachedColumns = [columnMapping valueForKey:[self tableName]];
    if (cachedColumns != nil)
    {
        return cachedColumns;
    }
    
    NSMutableArray *columns = [NSMutableArray array];
    
    NSString *schemaQuery = [NSString stringWithFormat:@"PRAGMA table_info(\"%@\")", [self tableName]];
    
    sqlite3_stmt *queryStatement = NULL;
    if (sqlite3_prepare([self database].database, [schemaQuery UTF8String], -1, &queryStatement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(queryStatement) == SQLITE_ROW)
        {
            // Extract the column's metadata
            // cid|name|type|notnull|dflt_value|pk
            NSInteger columnId = sqlite3_column_int(queryStatement, 0);
            NSString *name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryStatement, 1)];
            
            // TODO: There's got to be a better way to do this
            NSString *typeStr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(queryStatement, 2)];
            SQLiteColumnType type = kSQLiteColumnTypeNull;
            
            if ([typeStr rangeOfString:@"INT"].location != NSNotFound)
            {
                type = kSQLiteColumnTypeInteger;
            }
            else if ([typeStr rangeOfString:@"CHAR"].location != NSNotFound ||
                     [typeStr rangeOfString:@"CLOB"].location != NSNotFound ||
                     [typeStr rangeOfString:@"TEXT"].location != NSNotFound)
            {
                type = kSQLiteColumnTypeText;
            }
            else if ([typeStr isEqualToString:@"BLOB"])
            {
                type = kSQLiteColumnTypeBlob;
            }
            else if ([typeStr rangeOfString:@"REAL"].location != NSNotFound ||
                     [typeStr rangeOfString:@"FLOA"].location != NSNotFound ||
                     [typeStr rangeOfString:@"DOUB"].location != NSNotFound)
            {
                type = kSQLiteColumnTypeFloat;
            }
            
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
    [columnMapping setObject:columns forKey:[self tableName]];
    
    return columns;
}

id getSQLiteAttributeIMP(MLBase *self, SEL _cmd)
{
    NSString *getterName = NSStringFromSelector(_cmd);
    id value = [self->_attributes valueForKey:getterName];
    
    return (returnNilForNull && value == [NSNull null]) ? nil : value;
}

void setSQLiteAttributeIMP(MLBase *self, SEL _cmd, id newValue)
{
    // TODO: Make sure the value changed
    
    NSString *setterName = NSStringFromSelector(_cmd);
    
    // Remove the 'set' in front and downcase the first letter
    NSRange setRange = [setterName rangeOfString:@"set"];
    NSString *keyName = nil;
    
    if (setRange.location != NSNotFound)
    {
        keyName = [[setterName substringFromIndex:NSMaxRange(setRange)] lowerCamelCaseString];
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
    
    // We can't put nil into a dictionary
    if (newValue == nil)
    {
        newValue = [NSNull null];
    }
    
    // Update the attribute dict as well as the changed attribute dict
    [self->_attributes setValue:newValue forKey:keyName];
    [self->_changedAttributes setValue:newValue forKey:keyName];
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p>(%@)", NSStringFromClass([self class]), self, [_attributes description]];
}


#pragma mark - Finders

+ (MLBase *)first
{
    __block MLBase *fetchedObject = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM \"%@\" ORDER BY id ASC LIMIT 1", [self tableName]];
    
    [self fetchObjectsWithQuery:query withBlock:^(MLBase *matchingObject) {
        fetchedObject = matchingObject;
    }];
    
    return [fetchedObject autorelease];
}

+ (MLBase *)last
{
    __block MLBase *fetchedObject = nil;
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM '%@' ORDER BY id DESC LIMIT 1", [self tableName]];
    
    [self fetchObjectsWithQuery:query withBlock:^(MLBase *matchingObject) {
        fetchedObject = matchingObject;
    }];
    
    return fetchedObject;
}

+ (NSArray *)all
{
    NSMutableArray *fetchedObjects = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM '%@'", [self tableName]];
    
    [self fetchObjectsWithQuery:query withBlock:^(MLBase *matchingObject) {
        [fetchedObjects addObject:matchingObject];
    }];
    
    return fetchedObjects;
}

+ (NSArray *)findWithCriteria:(NSString *)criteria
{
    NSMutableArray *matchingObjects = [NSMutableArray array];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM \"%@\" WHERE %@", [self tableName], criteria];
    
    [self fetchObjectsWithQuery:query withBlock:^(MLBase *matchingObject) {
        [matchingObjects addObject:matchingObject];
    }];
    
    return matchingObjects;
}

NSDictionary *sqlite3Step(sqlite3_stmt *aStatement)
{
    int result = 0;
    int columnCount = 0;
    
    result = sqlite3_step(aStatement);
    columnCount = sqlite3_column_count(aStatement);
    
    NSMutableDictionary *attributes = nil;
    
    switch (result)
    {
        case SQLITE_ROW:
            attributes = [NSMutableDictionary dictionaryWithCapacity:columnCount];
            for (int i = 0; i < columnCount; ++i)
            {
                id value = nil;
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(aStatement, i)];
                int byteCount = 0;
                
                switch (sqlite3_column_type(aStatement, i))
                {
                    case SQLITE_INTEGER:
                        value = [NSNumber numberWithLongLong:sqlite3_column_int64(aStatement, i)];
                        break;
                    case SQLITE_FLOAT:
                        value = [NSNumber numberWithDouble:sqlite3_column_double(aStatement, i)];
                        break;
                    case SQLITE_TEXT:
                        value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(aStatement, i)];
                        break;
                    case SQLITE_BLOB:
                        byteCount = sqlite3_column_bytes(aStatement, i);
                        value = [NSData dataWithBytes:sqlite3_column_blob(aStatement, i) length:byteCount];
                        break;
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
            
            break;
        case SQLITE_DONE:
            return nil;
        case SQLITE_CONSTRAINT:
            NSLog(@"Constraint violation!");
            break;
        default:
            break;
    }
    
    return attributes;
}

+ (void)evaluateQuery:(NSString *)queryString withBlock:(void (^)(NSDictionary *attributes))block
{
    sqlite3_stmt *queryStatement = NULL;
    
    if (sqlite3_prepare_v2([self database].database, [queryString UTF8String], -1, &queryStatement, NULL) == SQLITE_OK)
    {
        NSDictionary *attributes = nil;
        
        while ((attributes = sqlite3Step(queryStatement)))
        {
            if (block != NULL)
            {
                block(attributes);
            }
        }
    }
    
    sqlite3_finalize(queryStatement);
}

+ (void)fetchObjectsWithQuery:(NSString *)queryString withBlock:(void (^)(MLBase *obj))block
{
    if (block == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"'block' cannot be nil"];
    }
    
    [self evaluateQuery:queryString withBlock:^(NSDictionary *objAttrs) {
        MLBase *obj = [[self alloc] initWithAttributes:objAttrs];
        obj.newRecord = NO;
        block(obj);
        [obj release];
    }];
}


#pragma mark - Object Lifecycle

- (id)init
{
    return [self initWithAttributes:nil];
}

- (id)initWithAttributes:(NSDictionary *)newAttributes
{
    self = [super init];
    
    if (self)
    {
        _attributes = [[NSMutableDictionary alloc] initWithDictionary:newAttributes];
        _changedAttributes = [[NSMutableDictionary alloc] initWithCapacity:newAttributes.count];
        
        // Default attributes
        _newRecord = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [_attributes release];
    [_changedAttributes release];
    
    [super dealloc];
}


#pragma mark -

- (BOOL)save
{
    // TODO: Validate attributes
    
    BOOL success = [self createOrUpdate];
    
    if (success)
    {
        // Clear our changed attributes
        [_changedAttributes removeAllObjects];
    }
    
    return success;
}

- (BOOL)createOrUpdate
{
    return (self.newRecord) ? [self create] : [self update];
}

- (BOOL)update
{
    // Build the SQL query
    NSMutableString *updateQueryString = [NSMutableString stringWithFormat:@"UPDATE \"%@\" SET ",
                                          [[self class] tableName]];
    
    NSArray *changedColumns = [_changedAttributes allKeys];
    for (int i = 0; i < changedColumns.count; ++i)
    {
        NSString *changedColumnName = [changedColumns objectAtIndex:i];
        id value = [_changedAttributes valueForKey:changedColumnName];
        
        if (![value isKindOfClass:[NSString class]])
        {
            // TODO: Support blobs
            value = [value stringValue];
        }
        
        value = [NSString stringWithFormat:@"\"%@\"", value];
        
        [updateQueryString appendFormat:@"\"%@\"=%@", changedColumnName, value];
        
        if (i < changedColumns.count - 1)
        {
            [updateQueryString appendString:@","];
        }
    }
    
    // Append the where clause
    [updateQueryString appendFormat:@" WHERE \"id\" == %lld", [self.id longLongValue]];
    
    // Fire the query
    [[self class] evaluateQuery:updateQueryString withBlock:NULL];
    
    return YES;  // TODO: Return the number of affected rows
}

- (BOOL)create
{
    // Build the SQL query
    NSMutableString *insertQueryString = [NSMutableString stringWithFormat:@"INSERT INTO \"%@\"(",
                                          [[self class] tableName]];
    
    NSArray *columns = [[self class] columns];
    NSString *columnNames = [[columns valueForKey:@"name"] componentsJoinedByString:@","];
    [insertQueryString appendFormat:@"%@) VALUES(", columnNames];
    
    for (int i = 0; i < columns.count; ++i)
    {
        MLColumn *column = [columns objectAtIndex:i];
        
        id value = [_attributes valueForKey:column.name];
        
        if (value == nil)
        {
            value = @"NULL";
        }
        else
        {
            if (![value isKindOfClass:[NSString class]])
            {
                // TODO: Support blobs
                value = [value stringValue];
            }
            
            value = [NSString stringWithFormat:@"\"%@\"", value];
        }
        
        [insertQueryString appendString:value];
        
        if (i < columns.count - 1)
        {
            [insertQueryString appendString:@","];
        }
        else
        {
            [insertQueryString appendString:@")"];
        }
    }
    
    // Fire the query
    [[self class] evaluateQuery:insertQueryString withBlock:NULL];
    
    // Mark as persisted and get the object's ID
    self.newRecord = NO;
    if ([self respondsToSelector:@selector(setId:)])
    {
        [self setId:[NSNumber numberWithLongLong:sqlite3_last_insert_rowid([[self class] database].database)]];
    }
    
    return YES;  // TODO: Return new record's ID
}

@end
