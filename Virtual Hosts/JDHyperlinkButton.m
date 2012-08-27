//
//  JDHyperlinkButton.m
//  Test 3
//
//  Created by Joe Dakroub on 8/21/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDHyperlinkButton.h"

@implementation JDHyperlinkButton

- (void)awakeFromNib
{
    [self setAction:@selector(openURL:)];
    [self setTarget:self];
}

- (IBAction)openURL:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self url]]];
}

//- (void)resetCursorRects
//{
//    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
//}

@end
