//
//  NSString+MerlinAdditions.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/14/11.
//  Copyright 2011-2012 AKQA, Inc. All rights reserved.
//

#import "NSString+MerlinAdditions.h"

@implementation NSString (MerlinAdditions)

- (NSString *)lowerCamelCaseString
{
    if (self.length == 0)
    {
        return self;
    }
    
    NSString *firstLetter = [[self substringToIndex:1] lowercaseString];
    NSString *remainder = [self substringFromIndex:1];
    return [firstLetter stringByAppendingString:remainder];
}

@end
