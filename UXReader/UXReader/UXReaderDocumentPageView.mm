//
//	UXReaderDocumentPageView.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocument.h"
#import "UXReaderDocumentPage.h"
#import "UXReaderDocumentPageView.h"
#import "UXReaderTiledLayer.h"
#import "UXReaderAppearance.h"
#import "UXReaderCanceller.h"
#import "UXReaderFramework.h"

@interface UXReaderDocumentPageView () <CALayerDelegate>

@end

@implementation UXReaderDocumentPageView
{
	UXReaderDocumentPage *documentPage;

	NSLayoutConstraint *sizeConstraintW;
	NSLayoutConstraint *sizeConstraintH;

	NSUInteger page; NSSize pageSize;
}

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UXReaderDocumentPageView instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		self.translatesAutoresizingMaskIntoConstraints = NO; self.wantsLayer = YES;

		CATiledLayer *tiled = [UXReaderTiledLayer layer]; tiled.delegate = self; self.layer = tiled;

		tiled.backgroundColor = [[UXReaderAppearance pageViewBackgroundColor] CGColor];

		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;

		self.layerContentsPlacement = NSViewLayerContentsPlacementCenter;

		page = NSUIntegerMax;
	}

	return self;
}

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)documentx page:(NSUInteger)pagex
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, documentx, pagex);

	if ((self = [self initWithFrame:NSZeroRect])) // Initialize self
	{
		if ((documentx != nil) && (pagex < [documentx pageCount]))
		{
			[self openPage:pagex document:documentx];
		}
		else // On failure
		{
			self = nil;
		}
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	self.layer.delegate = nil;
}

- (void)layout
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(self.bounds));

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout ", __FUNCTION__);
}

/*
- (void)removeFromSuperview
{
	//NSLog(@"%s", __FUNCTION__);

	self.layer.delegate = nil;

	[super removeFromSuperview];
}
*/

- (BOOL)isOpaque
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

- (void)openPage:(NSUInteger)pagex document:(nonnull UXReaderDocument *)document
{
	//NSLog(@"%s %lu %@", __FUNCTION__, page, document);

	page = pagex; pageSize = [document pageSize:page]; const CGFloat w = pageSize.width; const CGFloat h = pageSize.height;

	sizeConstraintW = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
													toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:w];

	sizeConstraintH = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
													toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:h];

	[self addConstraint:sizeConstraintW]; [self addConstraint:sizeConstraintH]; [self setMenu:[self contextMenu]];

	[UXReaderFramework dispatch_async_on_work_queue:
	^{
		if ((self->documentPage = [document documentPage:self->page]))
		{
			dispatch_async(dispatch_get_main_queue(),
			^{
				[self setNeedsDisplay:YES];
			});
		}
	}];
}

- (nonnull NSMenu *)contextMenu
{
	//NSLog(@"%s", __FUNCTION__);

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	NSFont *textFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];

	NSMenu *menu = [[NSMenu alloc] init]; [menu setFont:textFont]; NSMenuItem *menuItem = nil;

	menuItem = [[NSMenuItem alloc] init];
	menuItem.target = nil; menuItem.action = NSSelectorFromString(@"readerModeSinglePageStatic:");
	menuItem.title = [bundle localizedStringForKey:@"DisplayModeSinglePageStatic" value:nil table:nil];
	[menu addItem:menuItem];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.target = nil; menuItem.action = NSSelectorFromString(@"readerModeSinglePageScroll:");
	menuItem.title = [bundle localizedStringForKey:@"DisplayModeSinglePageScroll" value:nil table:nil];
	[menu addItem:menuItem];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.target = nil; menuItem.action = NSSelectorFromString(@"readerModeDoublePageStatic:");
	menuItem.title = [bundle localizedStringForKey:@"DisplayModeDoublePageStatic" value:nil table:nil];
	[menu addItem:menuItem];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.target = nil; menuItem.action = NSSelectorFromString(@"readerModeDoublePageScroll:");
	menuItem.title = [bundle localizedStringForKey:@"DisplayModeDoublePageScroll" value:nil table:nil];
	[menu addItem:menuItem];

	return menu;
}

- (NSUInteger)page
{
	//NSLog(@"%s", __FUNCTION__);

	return page;
}

- (NSSize)pageSize
{
	//NSLog(@"%s", __FUNCTION__);

	return pageSize;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
	//NSLog(@"%s %@ %p", __FUNCTION__, layer, context);

	[documentPage renderTileInContext:context view:self];
}

#pragma mark - NSResponder methods

- (void)mouseDown:(NSEvent *)event
{
	//NSLog(@"%s %@", __FUNCTION__, event);

	[super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event
{
	//NSLog(@"%s %@", __FUNCTION__, event);

	[super mouseDragged:event];
}

- (void)mouseUp:(NSEvent *)event
{
	//NSLog(@"%s %@", __FUNCTION__, event);

//	NSPoint point = [event locationInWindow];
//
//	point = [self convertPoint:point fromView:nil];
//
//	point = [documentPage convertViewPointToPage:point];
//
//	NSLog(@"%s %@", __FUNCTION__, NSStringFromPoint(point));

//	const NSSize size = UXAspectFitInSize(128.0, pageSize);
//
//	NSLog(@"%s %@", __FUNCTION__, NSStringFromSize(size));
//
//	UXReaderCanceller *canceller = [[UXReaderCanceller alloc] init];
//
//	[documentPage thumbWithSize:size canceller:canceller completion:^(NSImage *thumb)
//	{
//		NSLog(@"%s %@", __FUNCTION__, thumb);
//	}];

	[super mouseUp:event];
}

@end
