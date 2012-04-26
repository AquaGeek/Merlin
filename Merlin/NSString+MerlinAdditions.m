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
    
    NSRegularExpression *charactersToConvertRegEx = [NSRegularExpression regularExpressionWithPattern:@"([_-])([a-zA-Z\\d])"
                                                                                              options:0
                                                                                                error:NULL];
    
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

- (NSString *)underscoredString
{
    NSRegularExpression *doubleUppercaseRegEx = [NSRegularExpression regularExpressionWithPattern:@"([A-Z]+)([A-Z][a-z])"
                                                                                          options:0
                                                                                            error:NULL];
    NSRegularExpression *uppercaseRegEx = [NSRegularExpression regularExpressionWithPattern:@"([a-z\\d])([A-Z])"
                                                                                    options:0
                                                                                      error:NULL];
    
    NSString *result = nil;
    
    result = [doubleUppercaseRegEx stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@"$1_$2"];
    result = [uppercaseRegEx stringByReplacingMatchesInString:result options:0 range:NSMakeRange(0, result.length) withTemplate:@"$1_$2"];
    
    return [result lowercaseString];
}

@end
