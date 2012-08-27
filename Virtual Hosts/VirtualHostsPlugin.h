//
//  VirtualHostsPlugin.h
//  Virtual Hosts
//
//  Created by Joe Dakroub on 8/26/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "CodaPlugInsController.h"
#import "JDArrayController.h"
#import "RegexKitLite.h"
#import "VirtualHost.h"

@class CodaPlugInsController;

@interface VirtualHostsPlugin : NSObject <CodaPlugIn, NSWindowDelegate>

@end
