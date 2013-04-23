//
//  MLColumn.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011-2012 AKQA, Inc. All rights reserved.
//

#import "MLColumn.h"

@implementation MLColumn

+ (MLColumn *)columnWithId:(NSInteger)aColumnId
                      name:(NSString *)aName
                      type:(SQLiteColumnType)aType
                allowsNull:(BOOL)shouldAllowNull
{
    MLColumn *newColumn = [[MLColumn alloc] initWithId:aColumnId
                                                  name:aName
                                                  type:aType
                                            allowsNull:shouldAllowNull];
    return newColumn;
}

- (id)initWithId:(NSInteger)aColumnId
            name:(NSString *)aName
            type:(SQLiteColumnType)aType
      allowsNull:(BOOL)shouldAllowNull
{
    self = [super init];
    
    if (self != nil)
    {
        _columnId = aColumnId;
        _name = [aName copy];
        _type = aType;
        _allowsNull = shouldAllowNull;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%u)", self.name, self.type];
}

@end
