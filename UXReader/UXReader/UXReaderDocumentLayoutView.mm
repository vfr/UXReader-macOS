//
//	UXReaderDocumentLayoutView.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocument.h"
#import "UXReaderDocumentPage.h"
#import "UXReaderDocumentLayoutView.h"
#import "UXReaderDocumentPageView.h"
#import "UXReaderTextSelection.h"
#import "UXReaderAppearance.h"

@interface UXReaderDocumentLayoutView () <UXReaderDocumentPageViewDelegate>

@end

@implementation UXReaderDocumentLayoutView
{
	__strong UXReaderDocument *document;

	NSMutableDictionary<NSNumber *, NSValue *> *pageViewFrames;

	NSMutableDictionary<NSNumber *, UXReaderDocumentPageView *> *cachedPageViews;

	NSMutableDictionary<NSNumber *, UXReaderDocumentPageView *> *visiblePageViews;

	NSLayoutConstraint *sizeConstraintW; NSLayoutConstraint *sizeConstraintH;

	NSUInteger minimumPage, maximumPage, currentPage, pageCount;

	__weak UXReaderTextSelection *currentSelection;

	UXReaderDisplayMode displayMode;
}

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UXReaderDocumentLayoutView instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		self.translatesAutoresizingMaskIntoConstraints = NO; self.wantsLayer = YES;

		currentPage = minimumPage = maximumPage = NSUIntegerMax; pageCount = 0;

		displayMode = UXReaderDisplayModeSinglePageScroll; // Default mode

		cachedPageViews = [[NSMutableDictionary alloc] init];

		visiblePageViews = [[NSMutableDictionary alloc] init];

		pageViewFrames = [[NSMutableDictionary alloc] init];

		[self addShadow]; [self addSizeConstraints];
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

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout ", __FUNCTION__);
}

- (BOOL)isOpaque
{
	//NSLog(@"%s", __FUNCTION__);

	return NO;
}

- (void)drawRect:(NSRect)rect
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(rect));

	CGContextRef context = CGContextRef([[NSGraphicsContext currentContext] graphicsPort]);

	CGContextClearRect(context, rect);
}

- (void)addShadow
{
	//NSLog(@"%s", __FUNCTION__);

	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowOffset = NSZeroSize; shadow.shadowBlurRadius = 4.0;
	shadow.shadowColor = [UXReaderAppearance viewShadowColor];
	[self setShadow:shadow];
}

- (void)addSizeConstraints
{
	//NSLog(@"%s", __FUNCTION__);

	sizeConstraintW = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
													toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:0.0];

	sizeConstraintH = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
													toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:0.0];

	[self addConstraint:sizeConstraintW]; [self addConstraint:sizeConstraintH];
}

- (void)setSizeConstraints:(NSSize)size
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromSize(size));

	sizeConstraintW.constant = size.width; sizeConstraintH.constant = size.height;
}

- (nullable UXReaderDocument *)document
{
	//NSLog(@"%s", __FUNCTION__);

	return document;
}

- (void)setDocument:(nullable UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	if (documentx != document) // Change document
	{
		[self purgeAllPageViews]; currentSelection = nil;

		if (documentx != nil) // New valid UXReaderDocument
		{
			document = documentx; pageCount = [document pageCount];

			maximumPage = ((pageCount > 1) ? (pageCount - 1) : 0);

			minimumPage = 0; currentPage = NSUIntegerMax;
		}
		else // No document - reset things
		{
			currentPage = minimumPage = maximumPage = NSUIntegerMax;

			pageCount = 0; document = nil;
		}

		if ([delegate respondsToSelector:@selector(layoutView:didChangeDocument:)])
		{
			[delegate layoutView:self didChangeDocument:document];
		}
	}
}

- (void)setSelection:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (currentSelection != nil)
	{
		[currentSelection setHighlight:NO];

		const NSUInteger page = [currentSelection page];

		if (UXReaderDocumentPageView *pageView = visiblePageViews[@(page)])
		{
			[pageView setNeedsDisplay:YES];
		}

		currentSelection = nil;
	}

	if (selection != nil)
	{
		[selection setHighlight:YES];

		const NSUInteger page = [selection page];

		if (UXReaderDocumentPageView *pageView = visiblePageViews[@(page)])
		{
			[pageView setNeedsDisplay:YES];
		}

		currentSelection = selection;
	}
}

- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections
{
	//NSLog(@"%s %@", __FUNCTION__, selections);

	if (selections != [document searchSelections])
	{
		[document setSearchSelections:selections]; // New selections

		[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
		{
			[pageView setNeedsDisplay:YES];
		}];
	}
}

- (void)setDisplayMode:(UXReaderDisplayMode)mode
{
	//NSLog(@"%s %lu", __FUNCTION__, mode);

	if (mode != displayMode)
	{
		displayMode = mode; // Update mode

		switch (displayMode) // UXReaderDisplayMode
		{
			case UXReaderDisplayModeSinglePageStatic: { [self modeSinglePageStatic]; break; }
			case UXReaderDisplayModeSinglePageScroll: { [self modeSinglePageScroll]; break; }
			case UXReaderDisplayModeDoublePageStatic: { [self modeDoublePageStatic]; break; }
			case UXReaderDisplayModeDoublePageScroll: { [self modeDoublePageScroll]; break; }
		}

		if ([delegate respondsToSelector:@selector(layoutView:didChangeMode:)])
		{
			[delegate layoutView:self didChangeMode:displayMode];
		}
	}
}

- (UXReaderDisplayMode)displayMode
{
	//NSLog(@"%s", __FUNCTION__);

	return displayMode;
}

- (NSUInteger)pageCount
{
	//NSLog(@"%s", __FUNCTION__);

	return pageCount;
}

- (NSUInteger)currentPage
{
	//NSLog(@"%s", __FUNCTION__);

	return currentPage;
}

- (void)gotoPage:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if (document != nil)
	{
		switch (displayMode) // UXReaderDisplayMode
		{
			case UXReaderDisplayModeSinglePageStatic: { [self gotoPageSinglePageStatic:page]; break; }
			case UXReaderDisplayModeSinglePageScroll: { [self gotoPageSinglePageScroll:page]; break; }
			case UXReaderDisplayModeDoublePageStatic: { [self gotoPageDoublePageStatic:page]; break; }
			case UXReaderDisplayModeDoublePageScroll: { [self gotoPageDoublePageScroll:page]; break; }
		}
	}
}

- (void)gotoSelection:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (document != nil)
	{
		switch (displayMode) // UXReaderDisplayMode
		{
			case UXReaderDisplayModeSinglePageStatic: { [self gotoSelectionSinglePageStatic:selection]; break; }
			case UXReaderDisplayModeSinglePageScroll: { [self gotoSelectionSinglePageScroll:selection]; break; }
			case UXReaderDisplayModeDoublePageStatic: { [self gotoSelectionDoublePageStatic:selection]; break; }
			case UXReaderDisplayModeDoublePageScroll: { [self gotoSelectionDoublePageScroll:selection]; break; }
		}
	}
}

- (void)decrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canDecrementPage] == YES) [self gotoPage:(currentPage - 1)];
}

- (BOOL)canDecrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	return ((pageCount > 1) && (currentPage != minimumPage));
}

- (void)incrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canIncrementPage] == YES) [self gotoPage:(currentPage + 1)];
}

- (BOOL)canIncrementPage
{
	//NSLog(@"%s", __FUNCTION__);

	return ((pageCount > 1) && (currentPage != maximumPage));
}

- (BOOL)isShowingPages
{
	//NSLog(@"%s", __FUNCTION__);

	return (currentPage != NSUIntegerMax);
}

- (void)visibleRectDidChange
{
	//NSLog(@"%s", __FUNCTION__);

	if (document != nil)
	{
		switch (displayMode) // UXReaderDisplayMode
		{
			case UXReaderDisplayModeSinglePageStatic: { [self didScrollSinglePageStatic]; break; }
			case UXReaderDisplayModeSinglePageScroll: { [self didScrollSinglePageScroll]; break; }
			case UXReaderDisplayModeDoublePageStatic: { [self didScrollDoublePageStatic]; break; }
			case UXReaderDisplayModeDoublePageScroll: { [self didScrollDoublePageScroll]; break; }
		}
	}
}

- (void)purgeAllPageViews
{
	//NSLog(@"%s", __FUNCTION__);

	[cachedPageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		if ([pageView superview] != nil) [pageView removeFromSuperview];
	}];

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		if ([pageView superview] != nil) [pageView removeFromSuperview];
	}];

	[cachedPageViews removeAllObjects]; [visiblePageViews removeAllObjects]; [pageViewFrames removeAllObjects];

	[self setSizeConstraints:NSZeroSize];
}

- (nullable UXReaderDocumentPageView *)cachedPageView:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	UXReaderDocumentPageView *pageView = cachedPageViews[@(page)];

	if (pageView == nil) // Create a UXReaderDocumentPageView and optionally cache it
	{
		if ((pageView = [[UXReaderDocumentPageView alloc] initWithDocument:document page:page]))
		{
			pageView.delegate = self; if ([document prioritizePerformance]) cachedPageViews[@(page)] = pageView;
		}
	}

	return pageView;
}

- (void)removeVisiblePageViews
{
	//NSLog(@"%s", __FUNCTION__);

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		if ([pageView superview] != nil) [pageView removeFromSuperview];
	}];

	[visiblePageViews removeAllObjects];
}

- (void)scrollToViewTopLeft
{
	//NSLog(@"%s", __FUNCTION__);

	[self layoutSubtreeIfNeeded]; // Must be done before scrolling

	const CGFloat delta = (self.bounds.size.height - self.visibleRect.size.height);

	if (delta > 0.0) [self scrollPoint:NSMakePoint(0.0, delta)];
}

#pragma mark - UXReaderDisplayModeSinglePageStatic methods

- (void)modeSinglePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	[self removeVisiblePageViews];

	[pageViewFrames removeAllObjects];

	[self showPageSinglePageStatic:currentPage];
}

- (void)didScrollSinglePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	//const NSRect visibleRect = [self visibleRect];
}

- (void)gotoPageSinglePageStatic:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if ((page < pageCount) && (page != currentPage))
	{
		[self showPageSinglePageStatic:page];
	}
}

- (void)gotoSelectionSinglePageStatic:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (selection != nil)
	{
		[self gotoPageSinglePageStatic:[selection page]];
	}
}

- (void)showPageSinglePageStatic:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	NSMutableSet<NSNumber *> *wantedVisibleSet = [[NSMutableSet alloc] init];

	[wantedVisibleSet addObject:@(page)];

	NSMutableSet<NSNumber *> *currentlyVisibleSet = [[NSMutableSet alloc] init];

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		[currentlyVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *newVisibleSet = [wantedVisibleSet mutableCopy]; [newVisibleSet minusSet:currentlyVisibleSet];

	[newVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		if (UXReaderDocumentPageView *pageView = [self cachedPageView:[key unsignedIntegerValue]])
		{
			[self addSubview:pageView]; const NSSize size = [pageView pageSize]; [self setSizeConstraints:size]; self->visiblePageViews[key] = pageView;

			NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																	toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

			NSLayoutConstraint *l = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
																	toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];

			[self addConstraint:b]; [self addConstraint:l]; pageView.layoutConstraintY = b; pageView.layoutConstraintX = l; [self scrollToViewTopLeft];
		}
	}];

	NSMutableSet<NSNumber *> *notVisibleSet = [currentlyVisibleSet mutableCopy]; [notVisibleSet minusSet:wantedVisibleSet];

	[notVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		UXReaderDocumentPageView *pageView = self->visiblePageViews[key]; [pageView removeFromSuperview]; self->visiblePageViews[key] = nil;
	}];

	if (page != currentPage) // Update current page
	{
		currentPage = page; [delegate layoutView:self didChangePage:currentPage];
	}
}

#pragma mark - UXReaderDisplayModeSinglePageScroll methods

- (void)modeSinglePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	[self removeVisiblePageViews];

	[self setSizeConstraints:[self singlePageScrollViewSize]];

	[self showPageSinglePageScroll:currentPage];
}

- (void)didScrollSinglePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	const NSRect visibleRect = [self visibleRect];

	NSMutableSet<NSNumber *> *wantedVisibleSet = [[NSMutableSet alloc] init];

	[pageViewFrames enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSValue *value, BOOL *stop)
	{
		if (NSIntersectsRect([value rectValue], visibleRect) == YES) [wantedVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *currentlyVisibleSet = [[NSMutableSet alloc] init];

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		[currentlyVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *newVisibleSet = [wantedVisibleSet mutableCopy]; [newVisibleSet minusSet:currentlyVisibleSet];

	[newVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		if (UXReaderDocumentPageView *pageView = [self cachedPageView:[key unsignedIntegerValue]])
		{
			[self addSubview:pageView]; self->visiblePageViews[key] = pageView;

			if (NSValue *value = self->pageViewFrames[key]) // Position page view in layout view
			{
				const NSRect frame = [value rectValue]; const CGFloat x = frame.origin.x; const CGFloat y = -frame.origin.y;

				NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																		toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:y];

				NSLayoutConstraint *l = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
																		toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:x];

				[self addConstraint:b]; [self addConstraint:l]; pageView.layoutConstraintY = b; pageView.layoutConstraintX = l;
			}
		}
	}];

	NSMutableSet<NSNumber *> *notVisibleSet = [currentlyVisibleSet mutableCopy]; [notVisibleSet minusSet:wantedVisibleSet];

	[notVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		UXReaderDocumentPageView *pageView = self->visiblePageViews[key]; [pageView removeFromSuperview]; self->visiblePageViews[key] = nil;
	}];

	const CGFloat viewMiddleY = (visibleRect.origin.y + (visibleRect.size.height * 0.5));

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		if (NSValue *value = self->pageViewFrames[key])
		{
			const NSRect frame = [value rectValue];

			if ((frame.origin.y < viewMiddleY) && ((frame.origin.y + frame.size.height) > viewMiddleY))
			{
				const NSUInteger page = [key unsignedIntegerValue];

				if (page != self->currentPage) // Update current page
				{
					self->currentPage = page; [self->delegate layoutView:self didChangePage:self->currentPage];
				}
			}
		}
	}];
}

- (void)gotoPageSinglePageScroll:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if ((page < pageCount) && (page != currentPage))
	{
		if ([pageViewFrames count] == 0)
		{
			[self setSizeConstraints:[self singlePageScrollViewSize]];
		}

		[self showPageSinglePageScroll:page];
	}
}

- (void)gotoSelectionSinglePageScroll:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (selection != nil)
	{
		[self gotoPageSinglePageScroll:[selection page]];
	}
}

- (void)showPageSinglePageScroll:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if (NSValue *value = pageViewFrames[@(page)])
	{
		dispatch_async(dispatch_get_main_queue(), // Main queue scroll hack
		^{
			const NSRect frame = [value rectValue]; const NSRect visibleRect = [self visibleRect];

			const CGFloat y = ((frame.origin.y + frame.size.height) - visibleRect.size.height);

			[self scrollPoint:NSMakePoint(visibleRect.origin.x, ((y < 0.0) ? 0.0 : y))];
		});
	}
}

- (NSSize)singlePageScrollViewSize
{
	//NSLog(@"%s", __FUNCTION__);

	const CGFloat gap = [UXReaderAppearance pageSpaceGap];

	__block CGFloat totalHeight = gap; __block CGFloat totalWidth = 0.0;

	[document enumeratePageSizesUsingBlock:^(NSUInteger page, NSSize size)
	{
		totalHeight += (size.height + gap); if (totalWidth < size.width) totalWidth = size.width;
	}];

	[pageViewFrames removeAllObjects];

	__block CGFloat pageY = (totalHeight - gap);

	[document enumeratePageSizesUsingBlock:^(NSUInteger page, NSSize size)
	{
		pageY -= size.height; const CGFloat x = floor((totalWidth - size.width) * 0.5);

		NSRect frame; frame.size = size; frame.origin.x = x; frame.origin.y = pageY;

		self->pageViewFrames[@(page)] = [NSValue valueWithRect:frame]; pageY -= gap;
	}];

	return NSMakeSize(totalWidth, totalHeight);
}

#pragma mark - UXReaderDisplayModeDoublePageStatic methods

- (void)modeDoublePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	[self removeVisiblePageViews];

	[pageViewFrames removeAllObjects];

	[self showPageDoublePageStatic:currentPage];
}

- (void)didScrollDoublePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	//const NSRect visibleRect = [self visibleRect];
}

- (void)gotoPageDoublePageStatic:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if ((page < pageCount) && (page != currentPage))
	{
		[self showPageDoublePageStatic:page];
	}
}

- (void)gotoSelectionDoublePageStatic:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (selection != nil)
	{
		[self gotoPageDoublePageStatic:[selection page]];
	}
}

- (void)showPageDoublePageStatic:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	const CGFloat gap = [UXReaderAppearance pageSpaceGap];

	NSMutableSet<NSNumber *> *wantedVisibleSet = [[NSMutableSet alloc] init];

	const NSUInteger pageA = ((page >> 1) << 1); const NSUInteger pageB = (pageA + 1);

	[wantedVisibleSet addObject:@(pageA)]; if (pageB <= maximumPage) [wantedVisibleSet addObject:@(pageB)];

	NSMutableSet<NSNumber *> *currentlyVisibleSet = [[NSMutableSet alloc] init];

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		[currentlyVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *newVisibleSet = [wantedVisibleSet mutableCopy]; [newVisibleSet minusSet:currentlyVisibleSet];

	if ([newVisibleSet count] > 0) // Place page 'A'
	{
		if (UXReaderDocumentPageView *pageViewA = [self cachedPageView:pageA])
		{
			[self addSubview:pageViewA]; visiblePageViews[@(pageA)] = pageViewA; const NSSize sizeA = [pageViewA pageSize];

			NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:pageViewA attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																	toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

			NSLayoutConstraint *l = [NSLayoutConstraint constraintWithItem:pageViewA attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
																	toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];

			[self addConstraint:b]; [self addConstraint:l]; pageViewA.layoutConstraintY = b; pageViewA.layoutConstraintX = l;

			NSSize sizeT = sizeA; const CGFloat x2 = (sizeA.width + gap);

			if ([newVisibleSet count] > 1) // Place page 'B'
			{
				if (UXReaderDocumentPageView *pageViewB = [self cachedPageView:pageB])
				{
					[self addSubview:pageViewB]; visiblePageViews[@(pageB)] = pageViewB; const NSSize sizeB = [pageViewB pageSize];

					NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:pageViewB attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																			toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

					NSLayoutConstraint *l = [NSLayoutConstraint constraintWithItem:pageViewB attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
																			toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:x2];

					[self addConstraint:b]; [self addConstraint:l]; pageViewB.layoutConstraintY = b; pageViewB.layoutConstraintX = l;

					sizeT.width += (sizeB.width + gap); if (sizeT.height < sizeB.height) sizeT.height = sizeB.height;

					if (sizeA.height < sizeT.height) pageViewA.layoutConstraintY.constant = floor((sizeA.height - sizeT.height) * 0.5);

					if (sizeB.height < sizeT.height) pageViewB.layoutConstraintY.constant = floor((sizeB.height - sizeT.height) * 0.5);
				}
			}

			[self setSizeConstraints:sizeT]; [self scrollToViewTopLeft];
		}
	}

	NSMutableSet<NSNumber *> *notVisibleSet = [currentlyVisibleSet mutableCopy]; [notVisibleSet minusSet:wantedVisibleSet];

	[notVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		UXReaderDocumentPageView *pageView = self->visiblePageViews[key]; [pageView removeFromSuperview]; self->visiblePageViews[key] = nil;
	}];

	if (page != currentPage) // Update current page
	{
		currentPage = page; [delegate layoutView:self didChangePage:currentPage];
	}
}

#pragma mark - UXReaderDisplayModeDoublePageScroll methods

- (void)modeDoublePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	[self removeVisiblePageViews];

	[self setSizeConstraints:[self doublePageScrollViewSize]];

	[self showPageDoublePageScroll:currentPage];
}

- (void)didScrollDoublePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	const NSRect visibleRect = [self visibleRect];

	NSMutableSet<NSNumber *> *wantedVisibleSet = [[NSMutableSet alloc] init];

	[pageViewFrames enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSValue *value, BOOL *stop)
	{
		if (NSIntersectsRect([value rectValue], visibleRect) == YES) [wantedVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *currentlyVisibleSet = [[NSMutableSet alloc] init];

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		[currentlyVisibleSet addObject:key];
	}];

	NSMutableSet<NSNumber *> *newVisibleSet = [wantedVisibleSet mutableCopy]; [newVisibleSet minusSet:currentlyVisibleSet];

	[newVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		if (UXReaderDocumentPageView *pageView = [self cachedPageView:[key unsignedIntegerValue]])
		{
			[self addSubview:pageView]; self->visiblePageViews[key] = pageView;

			if (NSValue *value = self->pageViewFrames[key]) // Position page view in layout view
			{
				const NSRect frame = [value rectValue]; const CGFloat x = frame.origin.x; const CGFloat y = -frame.origin.y;

				NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
																		toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:y];

				NSLayoutConstraint *l = [NSLayoutConstraint constraintWithItem:pageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
																		toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:x];

				[self addConstraint:b]; [self addConstraint:l]; pageView.layoutConstraintY = b; pageView.layoutConstraintX = l;
			}
		}
	}];

	NSMutableSet<NSNumber *> *notVisibleSet = [currentlyVisibleSet mutableCopy]; [notVisibleSet minusSet:wantedVisibleSet];

	[notVisibleSet enumerateObjectsUsingBlock:^(NSNumber *key, BOOL *stop)
	{
		UXReaderDocumentPageView *pageView = self->visiblePageViews[key]; [pageView removeFromSuperview]; self->visiblePageViews[key] = nil;
	}];

	const CGFloat viewMiddleY = (visibleRect.origin.y + (visibleRect.size.height * 0.5));

	[visiblePageViews enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, UXReaderDocumentPageView *pageView, BOOL *stop)
	{
		if (NSValue *value = self->pageViewFrames[key])
		{
			const NSRect frame = [value rectValue];

			if ((frame.origin.y < viewMiddleY) && ((frame.origin.y + frame.size.height) > viewMiddleY))
			{
				const NSUInteger page = [key unsignedIntegerValue];

				if (((page & 1) == 0) && (page != self->currentPage)) // Update current page
				{
					self->currentPage = page; [self->delegate layoutView:self didChangePage:self->currentPage];
				}
			}
		}
	}];
}

- (void)gotoPageDoublePageScroll:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if ((page < pageCount) && (page != currentPage))
	{
		if ([pageViewFrames count] == 0)
		{
			[self setSizeConstraints:[self doublePageScrollViewSize]];
		}

		[self showPageDoublePageScroll:page];
	}
}

- (void)gotoSelectionDoublePageScroll:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	if (selection != nil)
	{
		[self gotoPageDoublePageScroll:[selection page]];
	}
}

- (void)showPageDoublePageScroll:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	if (NSValue *value = pageViewFrames[@(page)])
	{
		dispatch_async(dispatch_get_main_queue(), // Main queue scroll hack
		^{
			const NSRect frame = [value rectValue]; const NSRect visibleRect = [self visibleRect];

			const CGFloat y = ((frame.origin.y + frame.size.height) - visibleRect.size.height);

			[self scrollPoint:NSMakePoint(visibleRect.origin.x, ((y < 0.0) ? 0.0 : y))];
		});
	}
}

- (NSSize)doublePageScrollViewSize
{
	//NSLog(@"%s", __FUNCTION__);

	const CGFloat gap = [UXReaderAppearance pageSpaceGap];

	NSDictionary<NSNumber *, NSValue *> *pageSizes = [document pageSizes];

	NSMutableDictionary<NSNumber *, NSValue *> *rowSizes = [[NSMutableDictionary alloc] init];

	const NSUInteger rows = (pageCount / 2); const NSUInteger left = (pageCount % 2);

	CGFloat totalHeight = gap; CGFloat totalWidth = 0.0; NSUInteger page = 0;

	for (NSUInteger row = 0; row < rows; row++)
	{
		const NSSize sizeA = [pageSizes[@(page)] sizeValue]; page++;
		const NSSize sizeB = [pageSizes[@(page)] sizeValue]; page++;

		NSSize size = sizeA; if (size.height < sizeB.height) size.height = sizeB.height;

		size.width += (gap + sizeB.width); rowSizes[@(row)] = [NSValue valueWithSize:size];

		totalHeight += (size.height + gap); if (totalWidth < size.width) totalWidth = size.width;
	}

	if (left > 0)
	{
		const NSSize size = [pageSizes[@(page)] sizeValue];

		totalHeight += (size.height + gap); if (totalWidth < size.width) totalWidth = size.width;
	}

	[pageViewFrames removeAllObjects];

	CGFloat rowY = (totalHeight - gap); page = 0;

	for (NSUInteger row = 0; row < rows; row++)
	{
		const NSUInteger pageA = page++; const NSUInteger pageB = page++;

		const NSSize size = [rowSizes[@(row)] sizeValue]; rowY -= size.height;

		const NSSize sizeA = [pageSizes[@(pageA)] sizeValue];
		const NSSize sizeB = [pageSizes[@(pageB)] sizeValue];

		const CGFloat rxo = floor((totalWidth - size.width) * 0.5);

		const CGFloat xa = rxo; const CGFloat xb = (rxo + sizeA.width + gap);

		const CGFloat ya = (rowY + floor((size.height - sizeA.height) * 0.5));
		const CGFloat yb = (rowY + floor((size.height - sizeB.height) * 0.5));

		NSRect frameA; frameA.size = sizeA; frameA.origin.x = xa; frameA.origin.y = ya;
		NSRect frameB; frameB.size = sizeB; frameB.origin.x = xb; frameB.origin.y = yb;

		pageViewFrames[@(pageA)] = [NSValue valueWithRect:frameA];
		pageViewFrames[@(pageB)] = [NSValue valueWithRect:frameB];

		rowY -= gap;
	}

	if (left > 0)
	{
		const NSSize size = [pageSizes[@(page)] sizeValue]; rowY -= size.height;

		NSRect frame; frame.size = size; frame.origin.x = 0.0; frame.origin.y = rowY;

		pageViewFrames[@(page)] = [NSValue valueWithRect:frame];
	}

	return NSMakeSize(totalWidth, totalHeight);
}

#pragma mark - NSResponder methods

- (BOOL)acceptsFirstResponder
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

- (void)keyDown:(NSEvent *)event
{
	//NSLog(@"%s 0x%04X", __FUNCTION__, event.keyCode);

	if (document != nil)
	{
		switch (event.keyCode)
		{
			case 0x0073: // Home
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					[delegate scrollMinimumUsableX];
				else
					[delegate scrollMinimumUsableY];
				break;
			}

			case 0x0077: // End
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					[delegate scrollMaximumUsableX];
				else
					[delegate scrollMaximumUsableY];
				break;
			}

			case 0x0074: // Page up
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					[delegate scrollDecrementPageX];
				else
					[delegate scrollDecrementPageY];
				break;
			}

			case 0x0079: // Page dowm
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					[delegate scrollIncrementPageX];
				else
					[delegate scrollIncrementPageY];
				break;
			}
				
			case 0x007B: // Left arrow
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					if (event.modifierFlags & NSEventModifierFlagShift)
						[delegate scrollMinimumUsableX];
					else
						[delegate scrollDecrementPageX];
				else
					[delegate scrollDecrementLineX];
				break;
			}

			case 0x007C: // Right arrow
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					if (event.modifierFlags & NSEventModifierFlagShift)
						[delegate scrollMaximumUsableX];
					else
						[delegate scrollIncrementPageX];
				else
					[delegate scrollIncrementLineX];
				break;
			}

			case 0x007D: // Down arrow
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					if (event.modifierFlags & NSEventModifierFlagShift)
						[delegate scrollMaximumUsableY];
					else
						[delegate scrollIncrementPageY];
				else
					[delegate scrollIncrementLineY];
				break;
			}

			case 0x007E: // Up arrow
			{
				if (event.modifierFlags & NSEventModifierFlagCommand)
					if (event.modifierFlags & NSEventModifierFlagShift)
						[delegate scrollMinimumUsableY];
					else
						[delegate scrollDecrementPageY];
				else
					[delegate scrollDecrementLineY];
				break;
			}

			default: // None of the above
			{
				[super keyDown:event];
			}
		}
	}
	else // Follow chain
	{
		[super keyDown:event];
	}
}

/*
- (void)selectAll:(id)sender
{
	NSLog(@"%s %@", __FUNCTION__, sender);
}

- (void)pageDown:(id)sender
{
	NSLog(@"%s %@", __FUNCTION__, sender);
}
*/

#pragma mark - UXReaderDocumentPageViewDelegate methods

@end
