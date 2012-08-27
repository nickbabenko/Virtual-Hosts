//
//  JDEmptyView.m
//  Test 3
//
//  Created by Joe Dakroub on 8/20/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDEmptyView.h"

@implementation JDEmptyView


- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    [[self layer] setBackgroundColor:[[NSColor colorWithCalibratedRed:0.19f green:0.19f blue:0.19f alpha:0.3f] CGColor]];
    [[self layer] setBorderWidth:1.0];
    [[self layer] setBorderColor:[[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.1] CGColor]];
    [[self layer] setCornerRadius:8.0];
}

@end
