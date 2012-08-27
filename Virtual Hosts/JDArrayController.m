
//
//  JDArrayController.m
//  Test 3
//
//  Created by Joe Dakroub on 8/16/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "JDArrayController.h"

@interface JDArrayController ()
{
    NSUInteger arrangedObjectIndex;
}
@end

@implementation JDArrayController

- (void)addObject:(id)object
{
    VirtualHost *vhost = [[VirtualHost alloc] init];
    [vhost setDomainName:@"dev.domain.com"];
    [vhost setIPAddress:@"Any"];
    [vhost setLocalPath:@"/Library/WebServer/Documents"];
    [vhost setPort:@"80"];
    
    [super addObject:vhost];
}

- (void)duplicate:(id)sender
{
    VirtualHost *vhost = [[[self selectedObjects] lastObject] copy];
    [vhost setDomainName:[NSString stringWithFormat:@"%@ copy", [vhost domainName]]];
    
    [super addObject:vhost];
}

- (void)removeObjectAtArrangedObjectIndex:(NSUInteger)index
{
    arrangedObjectIndex = index;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeRequestedArrangedObject:) name:@"JDArrayControllerDidAcceptObjectRemoval" object:NULL];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JDArrayControllerRemoveObjectWasRequested" object:[[self arrangedObjects] objectAtIndex:index]];
}

- (void)removeRequestedArrangedObject:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JDArrayControllerDidAcceptObjectRemoval" object:NULL];
    
    [super removeObjectAtArrangedObjectIndex:arrangedObjectIndex];
}

@end
