//
//  MLColumn.h
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kSQLiteColumnTypeInteger = 1,
    kSQLiteColumnTypeFloat,
    kSQLiteColumnTypeText,
    kSQLiteColumnTypeBlob,
    kSQLiteColumnTypeNull
} SQLiteColumnType;

@interface MLColumn : NSObject {
@private
    NSInteger columnId;
    NSString *name;
    SQLiteColumnType type;
    BOOL allowsNull;
}

@property (nonatomic, assign) NSInteger columnId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) SQLiteColumnType type;
@property (nonatomic, assign) BOOL allowsNull;

+ (MLColumn *)columnWithId:(NSInteger)aColumnId
                      name:(NSString *)aName
                      type:(SQLiteColumnType)aType
                allowsNull:(BOOL)shouldAllowNull;

- (id)initWithId:(NSInteger)aColumnId
            name:(NSString *)aName
            type:(SQLiteColumnType)aType
      allowsNull:(BOOL)shouldAllowNull;

@end
