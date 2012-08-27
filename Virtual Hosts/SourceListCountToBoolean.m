//
//  SourceListCountToBoolean.m
//  Test 3
//
//  Created by Joe Dakroub on 8/16/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "SourceListCountToBoolean.h"

@implementation SourceListCountToBoolean

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
    if ([value intValue] == 1)
        return [NSNumber numberWithInt:1];
    
    return [NSNumber numberWithInt:0];
}

@end
