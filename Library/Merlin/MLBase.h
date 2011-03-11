/*!
 @header MLBase.h
 @copyright 2011 AKQA, Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import <sqlite3.h>

/*!
 @class MLBase
 @abstract Abstract base class for model classes that interact with an SQLite database.
 */
@interface MLBase : NSObject {
@private
    NSMutableDictionary *attributes;
}

/*!
 @methodgroup Configuration and setup
 */

/*!
 @method setDatabasePath:
 @abstract Sets the class-wide SQLite database to the file at the given path.
 @param pathToDatabase The full path to the database file on disk.
 @result Returns YES if the database was successfully opened or NO on error.
 */
+ (BOOL)setDatabasePath:(NSString *)pathToDatabase;

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

@end
