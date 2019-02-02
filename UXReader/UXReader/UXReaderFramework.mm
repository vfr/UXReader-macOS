//
//	UXReaderFramework.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderFramework.h"

#import "fpdfview.h"

@implementation UXReaderFramework
{
	dispatch_queue_t workQueue;
}

#pragma mark - Constants

static const char *const UXReaderFrameworkWorkQueue = "UXReaderFramework-WorkQueue";

#pragma mark - UXReaderFramework class methods

+ (nullable instancetype)sharedInstance
{
	static dispatch_once_t predicate = 0;

	static UXReaderFramework *singleton = nil;

	_dispatch_once(&predicate, ^{ singleton = [[self alloc] init]; });

	return singleton; // UXReaderFramework
}

+ (void)dispatch_sync_on_work_queue:(nonnull dispatch_block_t)block
{
	//NSLog(@"%s %p", __FUNCTION__, block);

	[[self sharedInstance] dispatch_sync_on_work_queue:block];
}

+ (void)dispatch_async_on_work_queue:(nonnull dispatch_block_t)block
{
	//NSLog(@"%s %p", __FUNCTION__, block);

	[[self sharedInstance] dispatch_async_on_work_queue:block];
}

+ (void)saveContextAsPNG:(nonnull CGContextRef)context
{
	//NSLog(@"%s %p", __FUNCTION__, context);

	if (CGImageRef image = CGBitmapContextCreateImage(context))
	{
		NSString *name = [NSString stringWithFormat:@"Context-%p.png", context];

		NSArray<NSURL *> *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];

		NSURL *url = [urls firstObject]; url = [url URLByAppendingPathComponent:name]; CFURLRef pngURL = (__bridge CFURLRef)url;

		const CGImageDestinationRef png = CGImageDestinationCreateWithURL(pngURL, (CFStringRef)@"public.png", 1, NULL); // PNG

		if (png != NULL) { CGImageDestinationAddImage(png, image, NULL); CGImageDestinationFinalize(png); CFRelease(png); }

		CGImageRelease(image);
	}
}

+ (BOOL)prioritizePerformance
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

#pragma mark - UXReaderFramework instance methods

- (instancetype)init
{
	//NSLog(@"%s", __FUNCTION__);

	if ((self = [super init])) // Initialize superclass
	{
		workQueue = dispatch_queue_create(UXReaderFrameworkWorkQueue, DISPATCH_QUEUE_SERIAL);

		FPDF_LIBRARY_CONFIG config; memset(&config, 0x00, sizeof(config));

		config.version = 2; FPDF_InitLibraryWithConfig(&config);
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);

	FPDF_DestroyLibrary();
}

- (void)dispatch_sync_on_work_queue:(nonnull dispatch_block_t)block
{
	//NSLog(@"%s %p", __FUNCTION__, block);

	const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);

	if (strcmp(label, UXReaderFrameworkWorkQueue) != 0)
		dispatch_sync(workQueue, block);
	else
		block();
}

- (void)dispatch_async_on_work_queue:(nonnull dispatch_block_t)block
{
	//NSLog(@"%s %p", __FUNCTION__, block);

	dispatch_async(workQueue, block);
}

@end

#pragma mark - UXReaderFramework functions
