//
//  MLColumn.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/10/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "MLColumn.h"

@implementation MLColumn

@synthesize columnId = _columnId;
@synthesize name = _name;
@synthesize type = _type;
@synthesize allowsNull = _allowsNull;

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
        _columnId = aColumnId;
        _name = [aName copy];
        _type = aType;
        _allowsNull = shouldAllowNull;
    }
    
    return self;
}

- (void)dealloc
{
    [_name release];
    
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", self.name, self.type];
}

@end
