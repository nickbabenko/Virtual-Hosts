//
//  JDHyperlinkButton.h
//  Test 3
//
//  Created by Joe Dakroub on 8/21/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JDHyperlinkButton : NSButton

@property (assign) NSString *url;

- (IBAction)openURL:(id)sender;

@end
