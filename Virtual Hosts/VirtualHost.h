//
//  VirtualHost.h
//  Test 3
//
//  Created by Joe Dakroub on 8/16/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"

@interface VirtualHost : NSObject <NSCopying>

@property (strong) NSString *domainName;
@property (strong) NSString *localPath;
@property (strong) NSString *IPAddress;
@property (strong) NSString *port;
@property (strong) NSMutableDictionary *directives;

- (id)initWithString:(NSString *)string;
- (NSString *)description;

@end
