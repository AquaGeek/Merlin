//
//  NSString+MerlinAdditions.h
//  Merlin
//
//  Created by Tyler Stromberg on 3/14/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MerlinAdditions)

/*!
 @method lowerCamelCaseString
 @abstract Returns the lowerCamelCase representation of the receiver.
 @return A string with the first character from the receiver changed to its corresponding lowercase value.
 */
- (NSString *)lowerCamelCaseString;

@end
