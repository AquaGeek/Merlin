/*!
 @header MLBase.h
 @copyright 2011-2012 AKQA, Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>

typedef enum {
    MLNamingStyleCamelCase = 0,
    MLNamingStyleSnakeCase
} MLNamingStyle;

@class MLDatabase;

/*!
 @class MLBase
 @abstract Abstract base class for model classes that interact with an SQLite database.
 */
@interface MLBase : NSObject

@property (nonatomic, retain) NSNumber *id;
@property (nonatomic, assign, getter = isNewRecord) BOOL newRecord;

/*!
 @method setReturnsNilForNull:
 @abstract Sets whether or not we should return nil for any NULL attributes in the database. By default,
 we return NSNull. Note: Changing this value affects all subclasses (i.e. it's a "master switch").
 */
+ (void)setReturnsNilForNull:(BOOL)returnNil;

+ (MLNamingStyle)namingStyle;
+ (void)setNamingStyle:(MLNamingStyle)newStyle;

/*!
 @methodgroup Configuration and setup
 */

/*!
 @method database
 @result Returns the MLDatabase that has been configured for the class via setDatabase:.
 */
+ (MLDatabase *)database;

/*!
 @method setDatabase:
 @abstract Sets the class-wide SQLite database.
 @param aDatabase The initialized MLDatabase object to use for this class.
 */
+ (void)setDatabase:(MLDatabase *)aDatabase;

/*!
 @method tableName
 @abstract Returns the name of the table corresponding to the model in the database. By default,
 the pluralized classname is returned. Subclasses can override this method to customize this behavior.
 @result Returns a String representing the name of the table in the database.
 */
+ (NSString *)tableName;

//!!! TEMP: Remove this
+ (NSArray *)columns;

/*!
 @methodgroup Finders
 */

+ (void)fetchObjectsWithQuery:(NSString *)queryString withBlock:(void (^)(MLBase *obj))block;

/*!
 @method first
 @abstract Finds the first record in the database, sorted by id.
 @result MLBase object
 */
+ (MLBase *)first;

/*!
 @method last
 @abstract Finds the last record in the database, sorted by id.
 @result MLBase object
 */
+ (MLBase *)last;

/*!
 @method all
 @abstract Retrieves all records in the database for this model.
 @result Array of MLBase objects
 */
+ (NSArray *)all;

/*!
 @method findWithCriteria:
 @abstract Retrieves all records in the database that match the given criteria.
 @result Array of MLBase objects matching the criteria
 */
+ (NSArray *)findWithCriteria:(NSString *)criteria;

/*!
 @methodgroup None
 */
- (id)initWithAttributes:(NSDictionary *)newAttributes;

- (BOOL)save;

@end
