//
//  JDFormView.m
//  Web Sharing 2
//
//  Created by Joe Dakroub on 8/15/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDFormView.h"

@interface JDFormView ()
{
    NSView *formView;
    NSView *fieldView;
}

@end

@implementation JDFormView

- (void)awakeFromNib
{
    NSRect frame = [self frame];
    
    // Base view
    [self setWantsLayer:YES];
    [[self layer] setCornerRadius:8.0];
    [[self layer] setShadowColor:[[NSColor blackColor] CGColor]];
    [[self layer] setShadowOffset:CGSizeMake(0.0, 0.0)];
    [[self layer] setShadowOpacity:0.2];
    [[self layer] setShadowRadius:2.0];
    
    // Form view
    formView = [[NSView alloc] initWithFrame:NSMakeRect(2.0, 2.0, frame.size.width - 4.0, frame.size.height - 4.0)];
    [formView setWantsLayer:YES];
    [[formView layer] setBackgroundColor:[[NSColor colorWithDeviceRed:0.97f green:0.97f blue:0.97f alpha:1.00f] CGColor]];
    [[formView layer] setBorderColor:[[NSColor colorWithDeviceRed:0.57f green:0.59f blue:0.61f alpha:1.00f] CGColor]];
    [[formView layer] setBorderWidth:1.0];
    [[formView layer] setCornerRadius:8.0];
    [[formView layer] setMasksToBounds:YES];
    [formView setAutoresizingMask:NSViewHeightSizable];
    
    // Field view
    fieldView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, round(frame.size.width + 1.0), round(frame.size.height - 100.0))];
    [fieldView setWantsLayer:YES];
    [[fieldView layer] setBackgroundColor:[[NSColor whiteColor] CGColor]];
    [[fieldView layer] setBorderColor:[[NSColor colorWithDeviceRed:0.75f green:0.75f blue:0.75f alpha:1.00f] CGColor]];
    [[fieldView layer] setBorderWidth:1.0];
    [fieldView setAutoresizingMask:NSViewHeightSizable];
    
    [self addSubview:formView positioned:NSWindowBelow relativeTo:nil];
    [formView addSubview:fieldView];
}

@end
