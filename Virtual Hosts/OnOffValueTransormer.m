//
//  OnOffValueTransormer.m
//  Test 3
//
//  Created by Joe Dakroub on 8/24/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "OnOffValueTransormer.h"

@implementation OnOffValueTransormer

+ (Class)transformedValueClass
{
    return [NSAttributedString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [value intValue] == 0 ? @"Web Sharing is off" : @"Web Sharing is on";
}

@end
