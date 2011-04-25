//
//  StringTests.h
//  Merlin
//
//  Created by Tyler Stromberg on 3/14/11.
//  Copyright 2011 AKQA, Inc. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

@interface StringTests : SenTestCase {
}

- (void)testMath;              // simple standalone test

- (void)testLowerCamelCase;

@end
