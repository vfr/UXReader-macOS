//
//	UXReaderDocumentView.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocument.h"
#import "UXReaderDocumentView.h"
#import "UXReaderDocumentClipView.h"
#import "UXReaderDocumentLayoutView.h"
#import "UXReaderTiledLayer.h"
#import "UXReaderAppearance.h"

@interface UXReaderDocumentView () <UXReaderDocumentClipViewDelegate, UXReaderDocumentLayoutViewDelegate>

@end

@implementation UXReaderDocumentView
{
	UXReaderDocumentLayoutView *layoutView;

	__strong UXReaderDocument *document;
}

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UXReaderDocumentView instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		self.translatesAutoresizingMaskIntoConstraints = NO; self.wantsLayer = YES;

		self.hasVerticalScroller = YES; self.hasHorizontalScroller = YES; self.autohidesScrollers = YES;

		if (UXReaderDocumentClipView *clipView = [[UXReaderDocumentClipView alloc] initWithFrame:NSZeroRect])
		{
			clipView.delegate = self; self.contentView = clipView; // UXReaderDocumentClipView

			self.backgroundColor = [UXReaderAppearance scrollViewBackgroundColor];

			self.maxMagnification = [UXReaderTiledLayer maximumZoom];

			self.minMagnification = [UXReaderTiledLayer minimumZoom];

			if ([self addDocumentView] == NO) self = nil;
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
	//NSLog(@"%s", __FUNCTION__);
}

- (void)layout
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(self.bounds));

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout", __FUNCTION__);
}

- (BOOL)allowsMagnification
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

- (BOOL)addDocumentView
{
	//NSLog(@"%s", __FUNCTION__);

	if ((layoutView = [[UXReaderDocumentLayoutView alloc] initWithFrame:NSZeroRect]))
	{
		self.documentView = layoutView; layoutView.delegate = self; // UXReaderDocumentLayoutViewDelegate

		[self addConstraint:[NSLayoutConstraint constraintWithItem:layoutView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
															toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

		[self addConstraint:[NSLayoutConstraint constraintWithItem:layoutView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
															toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];

		[self setMenu:[self contextMenu]];
	}

	return (layoutView != nil);
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

- (nullable UXReaderDocument *)document
{
	//NSLog(@"%s", __FUNCTION__);

	return document;
}

- (void)setDocument:(nullable UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	if (documentx != document) // Change UXReaderDocument
	{
		document = documentx; [layoutView setDocument:document];
	}
}

- (BOOL)hasDocument:(nullable UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	return [document isSameDocument:documentx];
}

- (void)setSelection:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	[layoutView setSelection:selection];
}

- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections
{
	//NSLog(@"%s %@", __FUNCTION__, selections);

	[layoutView setSearchSelections:selections];
}

- (void)gotoSelection:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	[layoutView gotoSelection:selection];
}

- (void)setDisplayMode:(UXReaderDisplayMode)mode
{
	//NSLog(@"%s %lu", __FUNCTION__, mode);

	[layoutView setDisplayMode:mode];
}

- (UXReaderDisplayMode)displayMode
{
	//NSLog(@"%s", __FUNCTION__);

	return [layoutView displayMode];
}

- (NSUInteger)pageCount
{
	//NSLog(@"%s", __FUNCTION__);

	return [layoutView pageCount];
}

- (NSUInteger)currentPage
{
	//NSLog(@"%s", __FUNCTION__);

	return [layoutView currentPage];
}

- (void)gotoPage:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	[layoutView gotoPage:page];
}

- (void)decrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	[layoutView decrementPage];
}

- (BOOL)canDecrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	return [layoutView canDecrementPage];
}

- (void)incrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	[layoutView incrementPage];
}

- (BOOL)canIncrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	return [layoutView canIncrementPage];
}

- (void)decrementZoom
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canDecrementZoom] == YES)
	{
		CGFloat value = (self.magnification / 1.25);

		if (value < self.minMagnification) value = self.minMagnification;

		[self updateZoom:value];
	}
}

- (BOOL)canDecrementZoom
{
	//NSLog(@"%s", __FUNCTION__);

	return ([layoutView isShowingPages] && (self.magnification > self.minMagnification));
}

- (void)incrementZoom
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canIncrementZoom] == YES)
	{
		CGFloat value = (self.magnification * 1.25);

		if (value > self.maxMagnification) value = self.maxMagnification;

		[self updateZoom:value];
	}
}

- (BOOL)canIncrementZoom
{
	//NSLog(@"%s", __FUNCTION__);

	return ([layoutView isShowingPages] && (self.magnification < self.maxMagnification));
}

- (void)zoomFitWidth
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canZoomFitWidth] == YES)
	{
		const CGFloat sw = [self bounds].size.width; const CGFloat dw = [[self documentView] bounds].size.width;

		const CGFloat cw = [NSScroller scrollerWidthForControlSize:NSControlSizeRegular scrollerStyle:NSScrollerStyleLegacy];

		if ((sw != 0.0) && (dw != 0.0)) { const CGFloat value = ((sw - cw) / dw); [self updateZoom:value]; }
	}
}

- (BOOL)canZoomFitWidth
{
	//NSLog(@"%s", __FUNCTION__);

	return ([layoutView isShowingPages] && [self allowsMagnification]);
}

- (void)zoomFitHeight
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canZoomFitHeight] == YES)
	{
		const CGFloat sh = [self bounds].size.height; const CGFloat dh = [[self documentView] bounds].size.height;

		const CGFloat ch = [NSScroller scrollerWidthForControlSize:NSControlSizeRegular scrollerStyle:NSScrollerStyleLegacy];

		if ((sh != 0.0) && (dh != 0.0)) { const CGFloat value = ((sh - ch) / dh); [self updateZoom:value]; }
	}
}

- (BOOL)canZoomFitHeight
{
	//NSLog(@"%s", __FUNCTION__);

	const UXReaderDisplayMode mode = [layoutView displayMode];

	const BOOL ok = ((mode == UXReaderDisplayModeSinglePageStatic) || (mode == UXReaderDisplayModeDoublePageStatic));

	return ([layoutView isShowingPages] && [self allowsMagnification] && ok);
}

- (void)zoomOneToOne
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canZoomOneToOne] == YES) [self updateZoom:1.0];
}

- (BOOL)canZoomOneToOne
{
	//NSLog(@"%s", __FUNCTION__);

	return ([layoutView isShowingPages] && (self.magnification != 1.0));
}

- (void)updateZoom:(CGFloat)value
{
	//NSLog(@"%s %g", __FUNCTION__, value);

	if (value != self.magnification)
	{
		self.magnification = value; // New magnification

		if ([delegate respondsToSelector:@selector(documentView:didChangeZoom:)])
		{
			[delegate documentView:self didChangeZoom:value];
		}
	}
}

#pragma mark - UXReaderDocumentView scroll methods

- (void)pageOriginX:(CGFloat)value
{
	//NSLog(@"%s %g", __FUNCTION__, value);

	const NSView *documentView = [self documentView]; if (documentView == nil) return;

	const NSRect bounds = [documentView bounds]; const NSRect visible = [documentView visibleRect];

	if (bounds.size.width > visible.size.width) // Document width larger than its visible area width
	{
		const CGFloat minimum = 0.0; const CGFloat maximum = (bounds.size.width - visible.size.width); NSPoint origin = visible.origin;

		CGFloat x = (origin.x + round(visible.size.width * value)); if (x < minimum) x = minimum; else if (x > maximum) x = maximum;

		origin.x = x; if (visible.origin.x != origin.x) [documentView scrollPoint:origin];
	}
}

- (void)pageOriginY:(CGFloat)value
{
	//NSLog(@"%s %g", __FUNCTION__, value);

	const NSView *documentView = [self documentView]; if (documentView == nil) return;

	const NSRect bounds = [documentView bounds]; const NSRect visible = [documentView visibleRect];

	if (bounds.size.height > visible.size.height) // Document height larger than its visible area height
	{
		const CGFloat minimum = 0.0; const CGFloat maximum = (bounds.size.height - visible.size.height); NSPoint origin = visible.origin;

		CGFloat y = (origin.y - round(visible.size.height * value)); if (y < minimum) y = minimum; else if (y > maximum) y = maximum;

		origin.y = y; if (visible.origin.y != origin.y) [documentView scrollPoint:origin];
	}
}

- (void)moveOriginX:(CGFloat)value
{
	//NSLog(@"%s %g", __FUNCTION__, value);

	const NSView *documentView = [self documentView]; if (documentView == nil) return;

	const NSRect bounds = [documentView bounds]; const NSRect visible = [documentView visibleRect];

	if (bounds.size.width > visible.size.width) // Document width larger than its visible area width
	{
		const CGFloat minimum = 0.0; const CGFloat maximum = (bounds.size.width - visible.size.width);

		NSPoint origin = visible.origin; if (value < 0.0) origin.x = minimum; else if (value > 0.0) origin.x = maximum;

		if (visible.origin.x != origin.x) [documentView scrollPoint:origin];
	}
}

- (void)moveOriginY:(CGFloat)value
{
	//NSLog(@"%s %g", __FUNCTION__, value);

	const NSView *documentView = [self documentView]; if (documentView == nil) return;

	const NSRect bounds = [documentView bounds]; const NSRect visible = [documentView visibleRect];

	if (bounds.size.height > visible.size.height) // Document height larger than its visible area height
	{
		const CGFloat minimum = 0.0; const CGFloat maximum = (bounds.size.height - visible.size.height);

		NSPoint origin = visible.origin; if (value < 0.0) origin.y = maximum; else if (value > 0.0) origin.y = minimum;

		if (visible.origin.y != origin.y) [documentView scrollPoint:origin];
	}
}

- (void)scrollDecrementLineX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginX:(-0.01)];
}

- (void)scrollDecrementLineY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginY:(-0.01)];
}

- (void)scrollIncrementLineX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginX:(+0.01)];
}

- (void)scrollIncrementLineY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginY:(+0.01)];
}

- (void)scrollDecrementPageX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginX:(-0.95)];
}

- (void)scrollDecrementPageY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginY:(-0.95)];
}

- (void)scrollIncrementPageX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginX:(+0.95)];
}

- (void)scrollIncrementPageY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self pageOriginY:(+0.95)];
}

- (void)scrollMinimumUsableX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self moveOriginX:(-1.00)];
}

- (void)scrollMinimumUsableY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self moveOriginY:(-1.00)];
}

- (void)scrollMaximumUsableX
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self moveOriginX:(+1.00)];
}

- (void)scrollMaximumUsableY
{
	//NSLog(@"%s", __FUNCTION__);

	if ([layoutView isShowingPages]) [self moveOriginY:(+1.00)];
}

#pragma mark - UXReaderClipViewDelegate methods

- (void)clipView:(NSClipView *)view boundsDidChange:(NSRect)bounds
{
	//NSLog(@"%s %@ %@", __FUNCTION__, view, NSStringFromRect(bounds));

	[layoutView visibleRectDidChange];
}

#pragma mark - UXReaderDocumentLayoutViewDelegate methods

- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangePage:(NSUInteger)page
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, view, page);

	if ([delegate respondsToSelector:@selector(documentView:didChangePage:)])
	{
		[delegate documentView:self didChangePage:page];
	}
}

- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangeDocument:(nullable UXReaderDocument *)documentx
{
	//NSLog(@"%s %@ %@", __FUNCTION__, view, documentx);

	if (self.magnification != 1.0) self.magnification = 1.0; // Reset

	if ([delegate respondsToSelector:@selector(documentView:didChangeDocument:)])
	{
		[delegate documentView:self didChangeDocument:documentx];
	}
}

- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangeMode:(UXReaderDisplayMode)mode
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, view, mode);

	if ([delegate respondsToSelector:@selector(documentView:didChangeMode:)])
	{
		[delegate documentView:self didChangeMode:mode];
	}
}

@end
