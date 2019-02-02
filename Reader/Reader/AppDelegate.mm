//
//	AppDelegate.mm
//	Reader v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "AppDelegate.h"

#import <UXReader/UXReader.h>

@interface AppDelegate () <UXReaderDocumentDataSource>

@end

@implementation AppDelegate
{
	NSMutableSet<NSWindowController *> *controllers;
	
	NSOpenPanel *readerOpenPanel;

	NSData *dataSource;
}

#pragma mark - AppDelegate instance methods

- (void)openReaderDocument:(nonnull NSURL *)URL
{
	//NSLog(@"%s %@", __FUNCTION__, URL);

//	if (dataSource == nil) dataSource = [NSData dataWithContentsOfURL:URL];

//	URL = [NSURL URLWithString:@"http://www.vfr.org/Stitch-Editor-Reference-Guide.pdf"];

	if (UXReaderDocument *document = [[UXReaderDocument alloc] initWithURL:URL])
//	if (UXReaderDocument *document = [[UXReaderDocument alloc] initWithSource:self])
	{
		BOOL showing = NO; // UXReaderDocument already showing flag

		for (NSWindowController *const controller in controllers)
		{
			UXReaderWindow *window = (UXReaderWindow *)controller.window;

			if ([window hasDocument:document] == YES) // Found the document
			{
				[window makeKeyAndOrderFront:nil]; showing = YES; break;
			}
		}

		if (showing == NO) // Create new UXReaderWindow with UXReaderDocument
		{
			[document openWithPassword:nil completion:^(NSError *error)
			{
				if (error == nil) // Show the new UXReaderDocument in a UXReaderWindow
				{
					if (UXReaderWindow *window = [[UXReaderWindow alloc] initWithDocument:document])
					{
						if (NSWindowController *controller = [[NSWindowController alloc] initWithWindow:window])
						{
							[self->controllers addObject:controller]; [controller showWindow:nil];
						}
					}
				}
				else // Log open error
				{
					NSLog(@"%s %@", __FUNCTION__, error);
				}
			}];
		}
	}
}

- (void)openReaderDocuments:(nonnull NSArray<NSURL *> *)URLs
{
	//NSLog(@"%s %@", __FUNCTION__, URLs);

	dispatch_async(dispatch_get_main_queue(),
	^{
		for (NSURL *URL in URLs) [self openReaderDocument:URL];
	});
}

- (void)handleSchemeRequest:(nonnull NSURL *)URL
{
	NSLog(@"%s %@", __FUNCTION__, URL);
}

#pragma mark - NSApplicationDelegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//NSLog(@"%s", __FUNCTION__);
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	//NSLog(@"%s", __FUNCTION__);

	controllers = [[NSMutableSet alloc] init]; [NSApp disableRelaunchOnLogin];

	NSAppleEventManager *nsaem = [NSAppleEventManager sharedAppleEventManager]; // Shared NSAppleEventManager

	[nsaem setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter]; // Default NSNotificationCenter

	[defaultCenter addObserver:self selector:@selector(windowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];

	if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_12) [NSWindow setAllowsAutomaticWindowTabbing:NO];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application
{
	//NSLog(@"%s", __FUNCTION__);

	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	//NSLog(@"%s", __FUNCTION__);
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filePath
{
	//NSLog(@"%s %@", __FUNCTION__, filePath);

	NSURL *URL = [NSURL fileURLWithPath:filePath isDirectory:NO];

	if (URL != nil) [self openReaderDocument:URL];

	return YES;
}

#pragma mark - NSAppleEventManager methods

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	//NSLog(@"%s", __FUNCTION__);

	NSString *request = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

	NSURL *URL = [NSURL URLWithString:request]; if (URL != nil) [self handleSchemeRequest:URL];
}

#pragma mark - NSResponder methods

- (void)openDocument:(id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	if (readerOpenPanel == nil) // Create an NSOpenPanel instance
	{
		readerOpenPanel = [NSOpenPanel openPanel]; NSBundle *mainBundle = [NSBundle mainBundle];

		readerOpenPanel.title = [mainBundle localizedStringForKey:@"Open Reader Document" value:nil table:nil];

		readerOpenPanel.allowsMultipleSelection = YES; readerOpenPanel.allowedFileTypes = @[@"pdf"];

		[readerOpenPanel beginWithCompletionHandler:^(NSInteger result) // NSOpenPanel handler
		{
			if (result == NSModalResponseOK) [self openReaderDocuments:[self->readerOpenPanel URLs]];

			self->readerOpenPanel = nil; // All done - release NSOpenPanel
		}];
	}
	else // NSOpenPanel exists
	{
		[readerOpenPanel makeKeyAndOrderFront:nil];
	}
}

- (void)showHelp:(id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);
}

#pragma mark - NSNotification methods

- (void)windowWillCloseNotification:(NSNotification *)notification
{
	//NSLog(@"%s %@", __FUNCTION__, notification);

	NSWindow *window = [notification object];

	if ([window isKindOfClass:[UXReaderWindow class]])
	{
		[controllers removeObject:[window windowController]];
	}
}

#pragma mark - UXReaderDocumentDataSource methods

- (BOOL)document:(UXReaderDocument *)document offset:(size_t)offset length:(size_t)length buffer:(uint8_t *)buffer
{
	//NSLog(@"%s %@ %lu %lu %p", __FUNCTION__, document, offset, length, buffer);

	if ([dataSource length] > 0) { memcpy(buffer, (reinterpret_cast<const uint8_t *>([dataSource bytes]) + offset), length); return YES; }

	return NO;
}

- (BOOL)document:(UXReaderDocument *)document dataLength:(size_t *)length
{
	//NSLog(@"%s %@ %p", __FUNCTION__, document, length);

	if (([dataSource length] > 0) && (length != nil)) { *length = [dataSource length]; return YES; }

	return NO;
}

#pragma mark - Miscellaneous methods

- (void)listAllWindowFrames
{
	//NSLog(@"%s", __FUNCTION__);

	const NSRect screenFrame = [[NSScreen mainScreen] frame];

	//const NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];

	//const CGFloat menuBarHeight = [[[NSApplication sharedApplication] mainMenu] menuBarHeight];

	const CGFloat screenWidth = screenFrame.size.width; //const CGFloat screenHeight = screenFrame.size.height;

	//NSLog(@"%s %@ %@ %g", __FUNCTION__, NSStringFromRect(screenFrame), NSStringFromRect(visibleFrame), menuBarHeight);

	NSArray<NSDictionary *> *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));

	for (NSDictionary *window in windows)
	{
		NSString *name = window[(__bridge NSString *)kCGWindowOwnerName];

		CFDictionaryRef dict = (__bridge CFDictionaryRef)(window[(__bridge NSString *)kCGWindowBounds]);

		CGRect rect = CGRectZero; CGRectMakeWithDictionaryRepresentation(dict, &rect);

		const CGFloat xc = ceil((screenWidth - rect.size.width) * 0.5);

		NSLog(@"%s '%@' %@ %g", __FUNCTION__, name, NSStringFromRect(rect), xc);
	}
}

@end
