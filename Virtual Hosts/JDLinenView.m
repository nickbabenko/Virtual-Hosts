//
//  JDLinenView.m
//  Web Sharing 2
//
//  Created by Joe Dakroub on 8/14/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDLinenView.h"
#import "VirtualHostsPlugin.h"

@implementation JDLinenView

CGFloat const kMargin = 10.0;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self setWantsLayer:YES];
        NSRect frame = [self frame];
                        
        NSView *shadowView = [[NSView alloc] initWithFrame:NSMakeRect(-kMargin, -kMargin, kMargin, frame.size.height + kMargin)];
        [shadowView setAutoresizingMask:NSViewHeightSizable];
        [shadowView setWantsLayer:YES];
        [[shadowView layer] setBackgroundColor:[[NSColor whiteColor] CGColor]];
        
        NSShadow *dropShadow = [[NSShadow alloc] init];
        [dropShadow setShadowColor:[NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.75]];
        [dropShadow setShadowOffset:NSMakeSize(0.0, 7.0)];
        [dropShadow setShadowBlurRadius:2.0];
        
        [shadowView setShadow:dropShadow];
        [self addSubview:shadowView];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSGraphicsContext* theContext = [NSGraphicsContext currentContext];
    [theContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0,[self frame].size.height)];
    
    NSImage *image = [[NSBundle bundleForClass:[VirtualHostsPlugin class]] imageForResource:@"Linen.png"];
    
    NSColor *linen = [NSColor colorWithPatternImage:image];
    [linen set];
    NSRectFill([self bounds]);
    [theContext restoreGraphicsState];
}

@end
