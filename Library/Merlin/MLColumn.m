//
//  MLColumn.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "MLColumn.h"

@implementation MLColumn

@synthesize columnId;
@synthesize name;
@synthesize type;
@synthesize allowsNull;

+ (MLColumn *)columnWithId:(NSInteger)aColumnId
                      name:(NSString *)aName
                      type:(SQLiteColumnType)aType
                allowsNull:(BOOL)shouldAllowNull
{
    MLColumn *newColumn = [[MLColumn alloc] initWithId:aColumnId
                                                  name:aName
                                                  type:aType
                                            allowsNull:shouldAllowNull];
    return [newColumn autorelease];
}

- (id)initWithId:(NSInteger)aColumnId
            name:(NSString *)aName
            type:(SQLiteColumnType)aType
      allowsNull:(BOOL)shouldAllowNull
{
    self = [super init];
    
    if (self != nil)
    {
        columnId = aColumnId;
        name = [aName copy];
        type = aType;
        allowsNull = shouldAllowNull;
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", name, type];
}

@end
