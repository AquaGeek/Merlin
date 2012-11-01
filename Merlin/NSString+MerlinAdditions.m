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
    
    NSMutableString *resultStr = [NSMutableString stringWithFormat:@"%@%@", firstLetter, remainder];
    
    NSRegularExpression *charactersToConvertRegEx = [self underscoreDashRegEx];
    
    __block NSInteger rangeOffset = 0;
    [charactersToConvertRegEx enumerateMatchesInString:resultStr
                                               options:0
                                                 range:NSMakeRange(0, resultStr.length)
                                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         NSRange overallRange = [result rangeAtIndex:0];
         overallRange.location -= rangeOffset;
         
         NSRange characterToCapitalizeRange = [result rangeAtIndex:2];
         characterToCapitalizeRange.location -= rangeOffset;
         
         NSString *characterToCapitalize = [[resultStr substringWithRange:characterToCapitalizeRange] uppercaseString];
         [resultStr replaceCharactersInRange:overallRange withString:characterToCapitalize];
         
         rangeOffset += characterToCapitalizeRange.length;
     }];
    
    return resultStr;
}

- (NSRegularExpression *)underscoreDashRegEx
{
    static NSRegularExpression *underscoreDashRegEx = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        underscoreDashRegEx = [[NSRegularExpression alloc] initWithPattern:@"([_-])([a-zA-Z\\d])" options:0 error:NULL];
    });
    
    return underscoreDashRegEx;
}

- (NSString *)underscoredString
{
    NSRegularExpression *doubleUppercaseRegEx = [self doubleUppercaseRegEx];
    NSRegularExpression *uppercaseRegEx = [self uppercaseRegEx];
    
    NSString *result = nil;
    
    result = [doubleUppercaseRegEx stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"$1_$2"];
    result = [uppercaseRegEx stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@"$1_$2"];
    
    return [result lowercaseString];
}

- (NSRegularExpression *)doubleUppercaseRegEx
{
    static NSRegularExpression *doubleUppercaseRegEx = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        doubleUppercaseRegEx = [[NSRegularExpression alloc] initWithPattern:@"([A-Z]+)([A-Z][a-z])" options:0 error:NULL];
    });
    
    return doubleUppercaseRegEx;
}

- (NSRegularExpression *)uppercaseRegEx
{
    static NSRegularExpression *uppercaseRegEx = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uppercaseRegEx = [[NSRegularExpression alloc] initWithPattern:@"([a-z\\d])([A-Z])" options:0 error:NULL];
    });
    
    return uppercaseRegEx;
}

@end
