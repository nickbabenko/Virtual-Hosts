//
//  VirtualHost.m
//  Test 3
//
//  Created by Joe Dakroub on 8/16/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "VirtualHost.h"

@implementation VirtualHost


- (id)copyWithZone:(NSZone *)zone
{
    VirtualHost *vhost = [[VirtualHost allocWithZone:zone] init];
    [vhost setDomainName:[self domainName]];
    [vhost setLocalPath:[self localPath]];
    [vhost setIPAddress:[self IPAddress]];
    [vhost setPort:[self port]];
    [vhost setDirectives:[self directives]];
    
    return vhost;
}

- (id)initWithString:(NSString *)string
{
    // Break directives into an array
    NSString *directivesRegexString = @"(?:\r\n|[\n\v\f\r\302\205\\p{Zl}\\p{Zp}])";
    NSMutableArray *directivesArray = [NSMutableArray arrayWithArray:[string componentsSeparatedByRegex:directivesRegexString]];
    
    if ([[directivesArray objectAtIndex:0] isEqualTo:@""])    
        [directivesArray removeObjectAtIndex:0];
    
    // Set IP/Port
    NSString *vhostIPPortString = [[directivesArray objectAtIndex:0] stringByMatching:@"[(\\*\\.)?\\:(\\d)]+"];
    NSArray *hostIPPortArray = [vhostIPPortString componentsSeparatedByString:@":"];
    
    // Pop off the first and last components
    [directivesArray removeObjectAtIndex:0];
    [directivesArray removeLastObject];
    
    NSMutableDictionary *directivesDictionary = [NSMutableDictionary dictionary];
    
    // Create new virtual host object
    VirtualHost *vh = [[VirtualHost alloc] init];
    
    // Add directives
    for (NSString *directive in directivesArray)
    {
        if ([directive isEqualTo:@""])
            continue;
        
        NSMutableArray *directiveParts = [NSMutableArray arrayWithArray:[directive componentsSeparatedByRegex:@"\"([^\"]*)\\\"|(\\S+)"]];
        
        // Clean up
        if ([[directiveParts objectAtIndex:0] isEqualTo:@""])
            [directiveParts removeObjectAtIndex:0];
        
        NSString *key = [[directiveParts objectAtIndex:2] stringByMatching:@"[^\\t]+"];
        NSString *value = [[directiveParts objectAtIndex:4] stringByMatching:@"[^\"]+"];

        // Don't add DocumentRoot or ServerName to directives dictionary
        if ([key isEqualTo:@"DocumentRoot"] || [key isEqualTo:@"ServerName"])
        {
            if ([key isEqualTo:@"ServerName"])
                [vh setDomainName:value];
            
            if ([key isEqualTo:@"DocumentRoot"])
                [vh setLocalPath:value];
            
            continue;
        }
        else
        {
            [directivesDictionary setValue:value forKey:key];
        }
    }
        
    [vh setDirectives:directivesDictionary];
    [vh setIPAddress:[[hostIPPortArray objectAtIndex:0] isEqualTo:@"*"] ? @"Any" : [hostIPPortArray objectAtIndex:0]];
    [vh setPort:[hostIPPortArray objectAtIndex:1]];
    
    return vh;
}

- (NSString *)description
{
    NSString *IPAddress = [[self IPAddress] isEqualTo:@"Any"] ? @"*" : [self IPAddress];
    NSString *description = [NSString stringWithFormat:@"<VirtualHost %@:%@>\n", IPAddress, [self port]];
    
    if ([[self directives] count] > 0)
    {
        for (NSString *key in [self directives])
        {
            description = [description stringByAppendingFormat:@"\t%@ %@\n", key, [[self directives] valueForKey:key]];
        }
    }
    
    description = [description stringByAppendingFormat:@"\tServerName \"%@\"\n", [self domainName]];
    description = [description stringByAppendingFormat:@"\tDocumentRoot \"%@\"\n", [self localPath]];
    description = [description stringByAppendingString:@"</VirtualHost>\n"];
    
    return description;
}

@end
