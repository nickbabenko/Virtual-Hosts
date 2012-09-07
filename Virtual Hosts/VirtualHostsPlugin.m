//
//  VirtualHostsPlugin.m
//  Virtual Hosts
//
//  Created by Joe Dakroub on 8/26/12.
//  Copyright (c) 2012 Joe Dakroub. All rights reserved.
//

#import "VirtualHostsPlugin.h"
#import "CodaPlugInsController.h"

NSString * const kMenuItemTitle = @"Virtual Hosts...";
NSString * const kPluginName = @"Virtual Hosts";

@interface VirtualHostsPlugin ()
{
    CodaPlugInsController *controller;    
    NSOpenPanel *openPanel;
    dispatch_source_t webServerStatusCheckTimer;
}

@property (unsafe_unretained) IBOutlet NSPopUpButton *actionButton;
@property (unsafe_unretained) IBOutlet NSButton *addVirtualHostButton;
@property (assign) NSString *defaultDirectiveKey;
@property (assign) NSString *defaultDirectiveValue;
@property (unsafe_unretained) IBOutlet NSDictionaryController *directivesDictionaryController;
@property (unsafe_unretained) IBOutlet NSTextField *domainNameLabel;
@property (assign) NSArray *IPAddresses;
@property (unsafe_unretained) NSString *localPath;
@property (copy) NSMutableArray *virtualHosts;
@property (unsafe_unretained) IBOutlet JDArrayController *virtualHostArrayController;
@property (assign) BOOL webServerEnabled;
@property (unsafe_unretained) IBOutlet NSTextField *webSharingLabel;
@property (unsafe_unretained) IBOutlet NSSegmentedControl *segmentedControl;
@property (unsafe_unretained) IBOutlet NSWindow *window;

- (id)initWithController:(CodaPlugInsController*)inController;

@end

@implementation VirtualHostsPlugin


NSString * const kApacheAccessLog = @"/opt/local/apache2/log/access_log";
NSString * const kApacheErrorLog = @"/opt/local/apache2/log/error_log";
CGFloat const kDataRowHeight = 22.0;
NSUInteger const kDefaultSelectionIndex = 1;
NSString * const kEditorName = @"Coda 2";
NSString * const kErrorLogApplication = @"Console";
CGFloat const kHeaderRowHeight = 17.0;
NSString * const kHostFile = @"/etc/hosts";
CGFloat const kLeftViewMinWidth = 150.0;
CGFloat const kLeftViewMaxWidth = 300.0;
NSString * const kVirtualHostBackupFile = @"/opt/local/apache2/conf/extra/httpd-vhosts~backup.conf";
NSString * const kVirtualHostFile = @"/opt/local/apache2/conf/extra/httpd-vhosts.conf";
NSString * const kVirtualHostPluginIdentifier = @"# Virtual Host Plugin for Coda 2";
NSString * const kVirtualHostRegex = @"[^#]<VirtualHost [^>]*>([^<]*)</VirtualHost>";
NSString * const kTempDirectory = @"/tmp";
NSString * const kWebServerEnabledString = @"/opt/local/apache2/bin/httpd -k start";

NSString * const kApacheBinFile = @"/opt/local/apache2/bin/apachectl";
NSString * const kApacheProcessFile = @"/opt/local/apache2/bin/httpd";

//2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController *)aController bundle:(NSBundle *)aBundle
{
    return [self initWithController:aController];
}

//2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController *)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle
{
    return [self initWithController:aController];
}

- (id)initWithController:(CodaPlugInsController *)inController
{
	if ( ! (self = [super init]))
        return nil;
    
    controller = inController;
    [controller registerActionWithTitle:NSLocalizedString(kMenuItemTitle, @"")
                  underSubmenuWithTitle:nil
                                 target:self
                               selector:@selector(showWindow:)
                      representedObject:self
                          keyEquivalent:@"^~@v"
                             pluginName:kPluginName];
    
	return self;
}

- (NSString *)name
{
	return kPluginName;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
	return YES;
}

- (void)showWindow:(id)sender
{
    if ([self window] == nil)
    {
        [NSBundle loadNibNamed:@"Window" owner:self];
    }
    
    // Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToObjectRemovalRequest:) name:@"JDArrayControllerRemoveObjectWasRequested" object:NULL];
    
    [[self directivesDictionaryController] addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self watchVirtualHostFile:kVirtualHostFile];
    
    // Data
    [self populateVirtualHosts:nil];
    [self populateIPAddresses];
    [self setDefaultDirectiveKey:@"Directive"];
    [self setDefaultDirectiveValue:@"Value"];
    [[self virtualHostArrayController] setSelectionIndex:kDefaultSelectionIndex];    

    // Open panel
    openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setMessage:NSLocalizedString(@"Choose the directory for the local path", @"")];
    [openPanel setPrompt:NSLocalizedString(@"Choose Directory", @"")];
    
    // Monitor web sharing status
    webServerStatusCheckTimer = CreateDispatchTimer(1ull * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self checkWebServerStatus:self];
    });
    
    // Controls
    [[self window] center];
    [[self window] makeKeyAndOrderFront:nil];
    [[self window] setDelegate:self];
    [[[self actionButton] cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[[self addVirtualHostButton] cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[[self domainNameLabel] cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[[self webSharingLabel] cell] setBackgroundStyle:NSBackgroundStyleRaised];    
    [[self segmentedControl] setEnabled:NO forSegment:1];
}

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selectedObjects"])
    {
        [[self segmentedControl] setEnabled:[[[self directivesDictionaryController] selectedObjects] count] > 0 forSegment:1];
    }
}

#pragma -
#pragma Alert/Window delegate

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1000)
    {
        if ([(__bridge NSString *)contextInfo isEqual:@"VirtualHostChangedAlert"])
        {
            [self populateVirtualHosts:nil];
        }
        else if ([(__bridge NSString *)contextInfo isEqual:@"VirtualHostFileMissing"])
        {
            [self createVirtualHostFile:nil];
        }
        else if ([(__bridge NSString *)contextInfo isEqual:@"VirtualHostBackupNotFound"])
        {
            [self backupVirtualHostFile:nil];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JDArrayControllerDidAcceptObjectRemoval" object:nil];
            NSBeep();
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    dispatch_source_cancel(webServerStatusCheckTimer);
    dispatch_release(webServerStatusCheckTimer);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JDArrayControllerRemoveObjectWasRequested" object:NULL];
    
    [[self directivesDictionaryController] removeObserver:self forKeyPath:@"selectedObjects"];
}

#pragma -
#pragma SplitView delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    return kLeftViewMaxWidth;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    return kLeftViewMinWidth;
}

#pragma -
#pragma Tableview DataSource/Delegates

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    return rowIndex != 0;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return row == 0 ? kHeaderRowHeight : kDataRowHeight;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [tableView makeViewWithIdentifier:row == 0 ? @"HeaderCell" : @"DataCell" owner:self];
}

#pragma -
#pragma TextField delegate

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *field = [notification object];
    
    if ([[field stringValue] isEqualTo:@""])
        [field setStringValue:[[field cell] placeholderString]];
}

#pragma -
#pragma Actions

- (IBAction)backupVirtualHostFile:(id)sender
{
    NSString *source = [NSString stringWithFormat:@"do shell script \"cp %@ %@\" with administrator privileges", kVirtualHostFile, kVirtualHostBackupFile];
    
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
    
    [script executeAndReturnError:nil];
}

- (void)presentBackupVirtualHostAlert
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"No backup file found"];
    [alert setInformativeText:@"There is no backup of your Virtual Host File.\n\nDo you wish to back it up now?\n"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)@"VirtualHostBackupNotFound"];
}

- (void)backupVirtualHostFileIfNeeded
{
    if ( ! [[NSFileManager defaultManager] fileExistsAtPath:kVirtualHostBackupFile])
    {
        [self presentBackupVirtualHostAlert];
    }
}

- (void)checkWebServerStatus:(id)sender
{
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"do shell script \"ps -ax | grep -i %@\"", kApacheProcessFile]];
    NSAppleEventDescriptor *event = [script executeAndReturnError:nil];
    
    [self setWebServerEnabled:[[event stringValue] rangeOfString:kWebServerEnabledString].length];
}

- (IBAction)createVirtualHostFile:(id)sender
{
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"do shell script \"echo NameVirtualHost *:80 > %@\" with administrator privileges", kVirtualHostFile]];
    
    if ([script executeAndReturnError:nil] != nil)
        [self populateVirtualHosts:nil];
}

- (IBAction)displayOpenSheet:(id)sender
{
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            VirtualHost *vhost = [[[self virtualHostArrayController] selectedObjects] lastObject];
            [vhost setLocalPath:[[openPanel URL] path]];
        }
    }];
}

- (void)displayVirtualHostChangedAlert:(id)sender
{
    NSBeep();
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Reload"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"The virtual host file has been changed by another application"];
    [alert setInformativeText:@"Do you wish to reload with the updated information?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)@"VirtualHostChangedAlert"];
}

- (IBAction)flushDNSCache:(id)sender
{
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"do shell script \"dscacheutil -flushcache\""];
    
    [script executeAndReturnError:nil];
}

- (IBAction)openApacheAccessLog:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:kApacheAccessLog withApplication:kEditorName];
}

- (IBAction)openApacheErrorLog:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:kApacheErrorLog withApplication:kEditorName];
}

- (IBAction)openDocumentationURL:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://httpd.apache.org/docs/2.2/mod/core.html"]];
}

- (IBAction)openHostsFile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:kHostFile withApplication:kEditorName];
}

- (IBAction)openVirtualHostFile:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:kVirtualHostFile withApplication:kEditorName];
}

- (IBAction)populateVirtualHosts:(id)sender
{
    NSUInteger selectedIndex = [[self virtualHostArrayController] selectionIndex];
    NSError *error = NULL;
    
    [self backupVirtualHostFileIfNeeded];
    
    NSString *fileNameString = [[NSString alloc] initWithContentsOfFile:kVirtualHostFile
                                                           usedEncoding:NULL
                                                                  error:&error];
    if (fileNameString)
    {
        NSMutableArray *vhostArray = [NSMutableArray array];
        [vhostArray addObject:[NSDictionary dictionaryWithObject:@"VIRTUAL HOSTS" forKey:@"title"]];
        
        NSArray *vhosts = [fileNameString componentsMatchedByRegex:kVirtualHostRegex];
        
        for (NSString *vhost in vhosts)
        {
            VirtualHost *vh = [[VirtualHost alloc] initWithString:vhost];
            
            [vh description];
            [vhostArray addObject:vh];
        }
        
        [self setVirtualHosts:vhostArray];
        [[self virtualHostArrayController] setSelectionIndex:selectedIndex != NSNotFound ? selectedIndex : kDefaultSelectionIndex];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Create Virtual Host File"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Error opening virtual host file"];
        [alert setInformativeText:[NSString stringWithFormat:@"%@\n", [error localizedDescription]]];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)@"VirtualHostFileMissing"];
    }
}

- (void)populateIPAddresses
{
    NSArray *hostAddresses = [[NSHost currentHost] addresses];
    NSMutableArray *addresses = [NSMutableArray arrayWithArray:hostAddresses];
    
    // Remove IP6 addresses
    for (NSString *address in hostAddresses)
    {
        if ( ! [address hasPrefix:@"127"] && [[address componentsSeparatedByString:@"."] count] != 4)
            [addresses removeObject:address];
    }
    
    // Sort ascending
    addresses = [NSMutableArray arrayWithArray:[addresses sortedArrayUsingComparator:^(NSString *a, NSString *b) {
        return [a compare:b options:NSNumericSearch];
    }]];
    
    [addresses insertObject:@"Any" atIndex:0];
    
    [self setIPAddresses:addresses];
}

- (void)respondToObjectRemovalRequest:(NSNotification *)note
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:[NSString stringWithFormat:@"Delete the virtual host \"%@\"?", [[note object] valueForKey:@"domainName"]]];
    [alert setInformativeText:@"This virtual host will remain active until you save your changes. This action cannot be undone.\n"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)note];
}

- (IBAction)toggleWebSharing:(id)sender
{
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"do shell script \"%@ %@\" with administrator privileges", kApacheBinFile, [sender intValue] == 0 ? @"stop" : @"restart"]];
    
    [script executeAndReturnError:nil];
}

- (IBAction)saveVirtualHostFile:(id)sender
{
    // Create string
    NSError *error = NULL;
    NSString *virtualHostsString = [[NSString alloc] initWithContentsOfFile:kVirtualHostFile
                                                               usedEncoding:NULL
                                                                      error:&error];
    
    NSString *replaced = [virtualHostsString stringByReplacingOccurrencesOfRegex:kVirtualHostRegex withString:@""];
    replaced = [replaced stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    replaced = [replaced stringByAppendingString:@"\n\n"];
    
    for (id vhost in [self virtualHosts])
    {
        if ([vhost isKindOfClass:[VirtualHost class]])
        {
            replaced = [replaced stringByAppendingFormat:@"%@\n", [vhost description]];
        }
    }
    
    // Write temporary file
    NSString *virtualHostTempFile = [NSString stringWithFormat:@"%@/httpd-vhosts.conf", kTempDirectory];
    [replaced writeToFile:virtualHostTempFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // Write to hosts file
    NSString *hostsString = [[NSString alloc] initWithContentsOfFile:kHostFile
                                                        usedEncoding:NULL
                                                               error:&error];
    
    replaced = [hostsString stringByReplacingOccurrencesOfRegex:[NSString stringWithFormat:@"%@\\n([a-zA-Z.\\t\\d\\s]*)%@", kVirtualHostPluginIdentifier, kVirtualHostPluginIdentifier] withString:@""];
    replaced = [replaced stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    replaced = [replaced stringByAppendingString:@"\n\n"];
    replaced = [replaced stringByAppendingFormat:@"%@\n", kVirtualHostPluginIdentifier];
    
    for (id vhost in [self virtualHosts])
    {
        if ([vhost isKindOfClass:[VirtualHost class]])
        {
            NSString *IPAddress = [[vhost IPAddress] isEqualTo:@"Any"] ? @"127.0.0.1" : [vhost IPAddress];
            replaced = [replaced stringByAppendingFormat:@"%@\t%@\n", IPAddress, [vhost domainName]];
        }
    }
    
    replaced = [replaced stringByAppendingString:kVirtualHostPluginIdentifier];
    
    // Write temporary file
    NSString *hostTempFile = [NSString stringWithFormat:@"%@/hosts.conf", kTempDirectory];
    [replaced writeToFile:hostTempFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // Write to permanent location
    NSString *source = [NSString stringWithFormat:@"do shell script \"cp %@ %@; cp %@ %@; %@ restart\" with administrator privileges", virtualHostTempFile, kVirtualHostFile, hostTempFile, kHostFile, kApacheBinFile];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
    
    [script executeAndReturnError:nil];
    
    NSDictionary *errorInfo = nil;
    script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"do shell script \"%@ -t\"", kApacheBinFile]];
    [script executeAndReturnError:&errorInfo];
    
    if (errorInfo != nil)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"There is a syntax error in one of your Virtual Host Directives"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:[errorInfo valueForKey:@"NSAppleScriptErrorMessage"]];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
}

- (IBAction)segmentedControlWasClicked:(id)sender
{
    if ([[self segmentedControl] selectedSegment] == 0)
    {
        [[self directivesDictionaryController] add:nil];
    }
    else
    {
        [[self directivesDictionaryController] remove:nil];
    }
}

- (void)watchVirtualHostFile:(NSString*)path;
{
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	int fildes = open([path UTF8String], O_EVTONLY);
    
    __block typeof(self) blockSelf = self;
	__block dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fildes,
															  DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE,
															  queue);
	dispatch_source_set_event_handler(source, ^{
        unsigned long flags = dispatch_source_get_data(source);
        
        if (flags & DISPATCH_VNODE_DELETE)
        {
            dispatch_source_cancel(source);
            [blockSelf watchVirtualHostFile:path];
        }
        
        if (flags == 17) // Data was saved
        {
            [self performSelectorOnMainThread:@selector(displayVirtualHostChangedAlert:) withObject:self waitUntilDone:YES];
        }
    });
    
	dispatch_source_set_cancel_handler(source, ^(void){
        close(fildes);
    });
    
	dispatch_resume(source);
}

@end
