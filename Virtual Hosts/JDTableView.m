//
//  JDTableView.m
//  Gradient Generator
//
//  Created by Joe Dakroub on 8/11/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDTableView.h"

@implementation JDTableView


- (void)deleteSelection
{
	[[self deleteControl] performClick:self];
}

- (void)deleteBackward:(id)inSender
{
	[self deleteSelection];
}

- (void)deleteForward:(id)inSender
{
	[self deleteSelection];
}

- (void)keyDown:(NSEvent *)event
{
	BOOL deleteKeyEvent = NO;
    
	// Check if the event was a keypress that matches either the backward or forward delete key.
	if ([event type] == NSKeyDown)
	{
		NSString *pressedChars = [event characters];
        
		if ([pressedChars length] == 1)
		{
			unichar pressedUnichar = [pressedChars characterAtIndex:0];
            
			if ((pressedUnichar == NSDeleteCharacter) || (pressedUnichar == NSDeleteFunctionKey))
			{
				deleteKeyEvent = YES;
			}
		}
	}
    
	if (deleteKeyEvent)
	{
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
	}
	else
	{
		[super keyDown:event];
	}
}

@end
