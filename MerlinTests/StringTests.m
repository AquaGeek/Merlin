//
//  StringTests.m
//  Merlin
//
//  Created by Tyler Stromberg on 3/14/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//

#import "StringTests.h"

#import "NSString+MerlinAdditions.h"

@implementation StringTests

- (void)testMath
{
    STAssertTrue((1+1)==2, @"Compiler isn't feeling well today :-(" );
}

- (void)testLowerCamelCase
{
    NSString *testStr = @"HelloSenKitTester";
    
    STAssertTrue([[testStr lowerCamelCaseString] isEqualToString:@"helloSenKitTester"],
                 @"lowerCamelCase value is not correct");
}

@end
