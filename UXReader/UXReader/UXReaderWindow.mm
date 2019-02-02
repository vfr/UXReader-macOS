//
//	UXReaderWindow.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderWindow.h"
#import "UXReaderToolbar.h"
#import "UXReaderDocument.h"
#import "UXReaderDocumentView.h"
#import "UXReaderTextSelection.h"
#import "UXReaderAppearance.h"

@interface UXReaderWindow () <NSWindowDelegate, UXReaderDocumentViewDelegate, UXReaderToolbarDelegate, UXReaderDocumentSearchDelegate>

@end

@implementation UXReaderWindow
{
	UXReaderToolbar *toolbarView;

	UXReaderDocumentView *documentView;

	NSMutableArray<UXReaderTextSelection *> *allSearchSelections;

	NSMutableDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *pageSearchSelections;

	__weak UXReaderTextSelection *currentSearchHighlight;

	NSString *searchText, *lastSearch;

	NSTimer *searchTimer;
}

#pragma mark - UXReaderWindow instance methods

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	NSRect contentRect = NSZeroRect; contentRect.size = [UXReaderAppearance minimumWindowSize];

	const NSUInteger style = (NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable);

	if ((self = [super initWithContentRect:contentRect styleMask:style backing:NSBackingStoreBuffered defer:YES])) // Initialize superclass
	{
		self.delegate = nil; self.contentMinSize = contentRect.size; self.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;

		[self presentWithContentRect:contentRect]; if ([self showDocument:documentx] == NO) self = nil;
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);
}

- (void)close
{
	//NSLog(@"%s", __FUNCTION__);

	[self cancelSearch];

	[super close];
}

- (void)presentWithContentRect:(NSRect)contentRect
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(contentRect));

	const NSRect vf = [[NSScreen mainScreen] visibleFrame]; // Useable area

	const CGFloat wh = (vf.size.height - [UXReaderAppearance verticalWindowInset]);

	const NSRect fr = [self frameRectForContentRect:contentRect]; const CGFloat mw = fr.size.width;

	const CGFloat ww = ((vf.size.width >= 1920.0) ? floor(wh * 0.75) : ((wh < mw) ? mw : wh));

	const CGFloat wy = floor(((vf.size.height - wh) * 0.5) + vf.origin.y); // Center Y

	const CGFloat wx = floor(((vf.size.width - ww) * 0.5) + vf.origin.x); // Center X

	[self setFrame:NSMakeRect(wx, wy, ww, wh) display:YES]; [self preventOverlap];
}

- (void)preventOverlap
{
	//NSLog(@"%s", __FUNCTION__);

	NSMutableSet<NSValue *> *origins = [[NSMutableSet alloc] init];

	NSArray<NSWindow *> *windows = [[NSApplication sharedApplication] windows];

	[windows enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger index, BOOL *stop)
	{
		if ((window != self) && ([window isKindOfClass:[UXReaderWindow class]] == YES))
		{
			[origins addObject:[NSValue valueWithPoint:window.frame.origin]];
		}
	}];

	const NSRect vf = [[NSScreen mainScreen] visibleFrame];

	NSPoint origin = self.frame.origin; const CGFloat step = 16.0;

	if ([origins containsObject:[NSValue valueWithPoint:origin]])
	{
		origin.x = (vf.origin.x + step);
	}

	const NSUInteger limit = (vf.size.width - self.frame.size.width - step);

	while ([origins containsObject:[NSValue valueWithPoint:origin]]) // Next X
	{
		origin.x += step; if (origin.x > limit) { origin = self.frame.origin; break; }
	}

	if (NSEqualPoints(self.frame.origin, origin) == NO)
	{
		[self setFrameOrigin:origin];
	}
}

- (BOOL)hasDocument:(nonnull UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	return [documentView hasDocument:documentx];
}

- (BOOL)showDocument:(nonnull UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	if (![documentx isKindOfClass:[UXReaderDocument class]]) return NO;

	BOOL status = NO; const NSView *view = self.contentView; // Window view

	if ((documentView = [[UXReaderDocumentView alloc] initWithFrame:NSZeroRect]))
	{
		toolbarView = [[UXReaderToolbar alloc] initWithFrame:NSZeroRect]; // UXReaderToolbar

		[view addSubview:toolbarView]; [toolbarView setDelegate:self]; // UXReaderToolbarDelegate

		[view addSubview:documentView]; [documentView setDelegate:self]; // UXReaderDocumentViewDelegate

		[view addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:toolbarView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:documentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
															toItem:toolbarView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:documentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:documentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:documentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
															toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

		[toolbarView buildKeyViewLoopWithView:documentView]; [toolbarView setPageCount:[documentx pageCount]]; status = YES; // Ok

		[view layoutSubtreeIfNeeded]; [documentView setDocument:documentx]; [documentView gotoPage:0]; documentx.search = self;

		if ([documentView acceptsFirstResponder] == YES) [self makeFirstResponder:documentView];
	}

	return status;
}

- (void)updateToolbarPageUI
{
	//NSLog(@"%s", __FUNCTION__);

	const NSUInteger page = ([documentView currentPage] + 1);

	[toolbarView showPageNumber:page ofPages:[documentView pageCount]];

	[toolbarView enablePageDecrement:[documentView canDecrementPage]];

	[toolbarView enablePageIncrement:[documentView canIncrementPage]];
}

- (void)updateToolbarZoomUI
{
	//NSLog(@"%s", __FUNCTION__);

	[toolbarView enableZoomDecrement:[documentView canDecrementZoom]];

	[toolbarView enableZoomIncrement:[documentView canIncrementZoom]];

	[toolbarView enableZoomFitAspect:[documentView canZoomFitWidth]];
}

- (void)updateWindowTitleUI
{
	//NSLog(@"%s", __FUNCTION__);

	self.title = [[documentView document] title];
}

#pragma mark - UXReaderWindow search methods

- (void)newSearchText:(nonnull NSString *)text
{
	//NSLog(@"%s %@", __FUNCTION__, text);

	if ([text length] > 0) // Search text
	{
		if ([text isEqualToString:searchText] == NO)
		{
			searchText = text; [self startSearchTimer];
		}
	}
	else // Close search
	{
		[self closeSearch];
	}
}

- (void)beginTextSearch:(nonnull NSString *)text
{
	//NSLog(@"%s %@", __FUNCTION__, text);

	if ([text length] > 0) // Begin search
	{
		if ([text isEqualToString:lastSearch] == NO) // New search term
		{
			searchText = text; [self cancelSearch]; [self startSearch:text];
		}
	}
	else // Close search
	{
		[self closeSearch];
	}
}

- (void)startSearch:(nonnull NSString *)text
{
	//NSLog(@"%s %@", __FUNCTION__, text);

	lastSearch = text; [toolbarView addRecentSearch:text];

	[toolbarView resetSearchUI]; [toolbarView showSearchUI:YES];

	[[documentView document] beginSearch:text options:UXReaderCaseInsensitiveSearchOption];
}

- (void)cancelSearch
{
	//NSLog(@"%s", __FUNCTION__);

	[self stopSearchTimer]; allSearchSelections = nil;

	pageSearchSelections = nil; [[documentView document] cancelSearch];

	[documentView setSearchSelections:nil];
}

- (void)closeSearch
{
	//NSLog(@"%s", __FUNCTION__);

	[self cancelSearch];

	lastSearch = nil; searchText = nil;

	[toolbarView showSearchUI:NO];
}

- (void)stopSearchTimer
{
	//NSLog(@"%s", __FUNCTION__);

	if (searchTimer != nil) { [searchTimer invalidate]; searchTimer = nil; }
}

- (void)startSearchTimer
{
	//NSLog(@"%s", __FUNCTION__);

	[self stopSearchTimer]; const NSTimeInterval ti = [UXReaderAppearance searchBeginTimer];

	searchTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:self selector:@selector(searchTimerFired:) userInfo:nil repeats:NO];
}

- (void)searchTimerFired:(nonnull NSTimer *)timer
{
	//NSLog(@"%s %@", __FUNCTION__, timer);

	[self cancelSearch]; [self startSearch:searchText];
}

- (void)decrementSearchHit
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canDecrementSearchHit])
	{
		[self searchHitDecrement];
	}
}

- (BOOL)canDecrementSearchHit
{
	//NSLog(@"%s", __FUNCTION__);

	return (pageSearchSelections != nil);
}

- (void)incrementSearchHit
{
	//NSLog(@"%s", __FUNCTION__);

	if ([self canIncrementSearchHit])
	{
		[self searchHitIncrement];
	}
}

- (BOOL)canIncrementSearchHit
{
	//NSLog(@"%s", __FUNCTION__);

	return (pageSearchSelections != nil);
}

- (void)searchHitDecrementPage:(BOOL)decrement
{
	//NSLog(@"%s %i", __FUNCTION__, decrement);

	const NSUInteger currentPage = [documentView currentPage]; NSUInteger page = currentPage;

	const NSUInteger minimumPage = 0; const NSUInteger maximumPage = ([[documentView document] pageCount]-1);

	if (decrement == YES) { if (page == minimumPage) page = maximumPage; else page--; }

	while (YES) // Loop until a page with selections is found or wrapped around
	{
		NSArray<UXReaderTextSelection *> *selections = pageSearchSelections[@(page)];

		if (selections == nil) // None on this page - decrement page
		{
			if (page == minimumPage) page = maximumPage; else page--;

			if (page == currentPage) break; // Wrapped around
		}
		else // Found a page with some selections - goto it
		{
			[self presentSelection:[selections lastObject]]; break;
		}
	}
}

- (void)searchHitIncrementPage:(BOOL)increment
{
	//NSLog(@"%s %i", __FUNCTION__, increment);

	const NSUInteger currentPage = [documentView currentPage]; NSUInteger page = currentPage;

	const NSUInteger minimumPage = 0; const NSUInteger maximumPage = ([[documentView document] pageCount]-1);

	if (increment == YES) { if (page == maximumPage) page = minimumPage; else page++; }

	while (YES) // Loop until a page with selections is found or wrapped around
	{
		NSArray<UXReaderTextSelection *> *selections = pageSearchSelections[@(page)];

		if (selections == nil) // None on this page - increment page
		{
			if (page == maximumPage) page = minimumPage; else page++;

			if (page == currentPage) break; // Wrapped around
		}
		else // Found a page with some selections - goto it
		{
			[self presentSelection:[selections firstObject]]; break;
		}
	}
}

- (void)searchHitDecrement
{
	//NSLog(@"%s", __FUNCTION__);

	if (currentSearchHighlight != nil) // Carry on
	{
		const NSUInteger page = [currentSearchHighlight page];

		if (NSArray<UXReaderTextSelection *> *selections = pageSearchSelections[@(page)])
		{
			const NSUInteger minimumIndex = 0; const NSUInteger maximumIndex = ([selections count]-1);

			const NSUInteger index = [selections indexOfObject:currentSearchHighlight];

			if (index != NSNotFound) // Found current selection in array
			{
				if ((index == minimumIndex) || (maximumIndex == minimumIndex))
				{
					[self searchHitDecrementPage:YES];
				}
				else // Highlight new selection on same page
				{
					[self presentSelection:[selections objectAtIndex:(index-1)]];
				}
			}
		}
	}
}

- (void)searchHitIncrement
{
	//NSLog(@"%s", __FUNCTION__);

	if (currentSearchHighlight != nil) // Carry on
	{
		const NSUInteger page = [currentSearchHighlight page];

		if (NSArray<UXReaderTextSelection *> *selections = pageSearchSelections[@(page)])
		{
			const NSUInteger minimumIndex = 0; const NSUInteger maximumIndex = ([selections count]-1);

			const NSUInteger index = [selections indexOfObject:currentSearchHighlight];

			if (index != NSNotFound) // Found current selection in array
			{
				if ((index == maximumIndex) || (minimumIndex == maximumIndex))
				{
					[self searchHitIncrementPage:YES];
				}
				else // Highlight new selection on same page
				{
					[self presentSelection:[selections objectAtIndex:(index+1)]];
				}
			}
		}
	}
}

- (void)presentSelection:(nonnull UXReaderTextSelection *)selection
{
	//NSLog(@"%s %@", __FUNCTION__, selection);

	currentSearchHighlight = selection;

	[documentView gotoSelection:selection];

	[documentView setSelection:selection];

	const NSUInteger index = [allSearchSelections indexOfObject:selection];

	if (index != NSNotFound) // Found current selection in array - update toolbar
	{
		[toolbarView showFound:(index + 1) of:[allSearchSelections count]];
	}
}

#pragma mark - UXReaderWindow IBAction methods

- (IBAction)readerGotoPage:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[toolbarView gotoPageFieldFocus];
}

- (IBAction)readerDecrementPage:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView decrementPage];
}

- (IBAction)readerIncrementPage:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView incrementPage];
}

- (IBAction)readerDecrementZoom:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView decrementZoom];
}

- (IBAction)readerIncrementZoom:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView incrementZoom];
}

- (IBAction)readerZoomFitWidth:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView zoomFitWidth];
}

- (IBAction)readerZoomFitHeight:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView zoomFitHeight];
}

- (IBAction)readerZoomOneToOne:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView zoomOneToOne];
}

- (IBAction)readerFindText:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[toolbarView findTextFieldFocus];
}

- (IBAction)readerDecrementFind:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[self decrementSearchHit];
}

- (IBAction)readerIncrementFind:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[self incrementSearchHit];
}

- (IBAction)readerModeSinglePageStatic:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView setDisplayMode:UXReaderDisplayModeSinglePageStatic];
}

- (IBAction)readerModeSinglePageScroll:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView setDisplayMode:UXReaderDisplayModeSinglePageScroll];
}

- (IBAction)readerModeDoublePageStatic:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView setDisplayMode:UXReaderDisplayModeDoublePageStatic];
}

- (IBAction)readerModeDoublePageScroll:(nullable id)sender
{
	//NSLog(@"%s %@", __FUNCTION__, sender);

	[documentView setDisplayMode:UXReaderDisplayModeDoublePageScroll];
}

#pragma mark - NSMenuValidation methods

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	//NSLog(@"%s %@", __FUNCTION__, menuItem);

	BOOL enable = NO; // Disabled default

	const SEL action = [menuItem action];

	if (action == @selector(readerGotoPage:))
	{
		enable = ((toolbarView != nil) ? YES : NO);
	}
	else if (action == @selector(readerDecrementPage:))
	{
		enable = [documentView canDecrementPage];
	}
	else if (action == @selector(readerIncrementPage:))
	{
		enable = [documentView canIncrementPage];
	}
	else if (action == @selector(readerDecrementZoom:))
	{
		enable = [documentView canDecrementZoom];
	}
	else if (action == @selector(readerIncrementZoom:))
	{
		enable = [documentView canIncrementZoom];
	}
	else if (action == @selector(readerZoomFitWidth:))
	{
		enable = [documentView canZoomFitWidth];
	}
	else if (action == @selector(readerZoomFitHeight:))
	{
		enable = [documentView canZoomFitHeight];
	}
	else if (action == @selector(readerZoomOneToOne:))
	{
		enable = [documentView canZoomOneToOne];
	}
	else if (action == @selector(readerFindText:))
	{
		enable = ((toolbarView != nil) ? YES : NO);
	}
	else if (action == @selector(readerDecrementFind:))
	{
		enable = [self canDecrementSearchHit];
	}
	else if (action == @selector(readerIncrementFind:))
	{
		enable = [self canIncrementSearchHit];
	}
	else if (action == @selector(readerModeSinglePageStatic:))
	{
		if (documentView) { menuItem.state = [self stateSinglePageStatic]; enable = YES; }
	}
	else if (action == @selector(readerModeSinglePageScroll:))
	{
		if (documentView) { menuItem.state = [self stateSinglePageScroll]; enable = YES; }
	}
	else if (action == @selector(readerModeDoublePageStatic:))
	{
		if (documentView) { menuItem.state = [self stateDoublePageStatic]; enable = YES; }
	}
	else if (action == @selector(readerModeDoublePageScroll:))
	{
		if (documentView) { menuItem.state = [self stateDoublePageScroll]; enable = YES; }
	}
	else // Next in menu validation chain
	{
		enable = [super validateMenuItem:menuItem];
	}

	return enable;
}

- (NSInteger)stateSinglePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	return (([documentView displayMode] == UXReaderDisplayModeSinglePageStatic) ? NSOnState : NSOffState);
}

- (NSInteger)stateSinglePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	return (([documentView displayMode] == UXReaderDisplayModeSinglePageScroll) ? NSOnState : NSOffState);
}

- (NSInteger)stateDoublePageStatic
{
	//NSLog(@"%s", __FUNCTION__);

	return (([documentView displayMode] == UXReaderDisplayModeDoublePageStatic) ? NSOnState : NSOffState);
}

- (NSInteger)stateDoublePageScroll
{
	//NSLog(@"%s", __FUNCTION__);

	return (([documentView displayMode] == UXReaderDisplayModeDoublePageScroll) ? NSOnState : NSOffState);
}

#pragma mark - UXReaderDocumentViewDelegate methods

- (void)documentView:(nonnull UXReaderDocumentView *)view didChangePage:(NSUInteger)page
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, view, page);

	[self updateToolbarPageUI]; [self updateToolbarZoomUI];
}

- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeDocument:(nullable UXReaderDocument *)documentx
{
	//NSLog(@"%s %@ %@", __FUNCTION__, view, documentx);

	if (documentx != nil) [self updateWindowTitleUI];

	[toolbarView enable:(documentx != nil)];
}

- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeMode:(UXReaderDisplayMode)mode
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, view, mode);

	//[self updateToolbarModeUI];
}

- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeZoom:(CGFloat)value
{
	//NSLog(@"%s %@ %g", __FUNCTION__, view, value);

	[self updateToolbarZoomUI];
}

#pragma mark - UXReaderToolbarDelegate methods

- (void)zoomFitAspect
{
	//NSLog(@"%s", __FUNCTION__);

	if ([NSEvent modifierFlags] & NSEventModifierFlagOption)
		[documentView zoomFitHeight];
	else
		[documentView zoomFitWidth];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar gotoPage:(NSUInteger)page
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, toolbar, page);

	[documentView gotoPage:page];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomFitAspect:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[self zoomFitAspect];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomDecrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[documentView decrementZoom];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomIncrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[documentView incrementZoom];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar pageDecrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[documentView decrementPage];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar pageIncrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[documentView incrementPage];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar findDecrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[self decrementSearchHit];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar findIncrement:(nullable id)object
{
	//NSLog(@"%s %@", __FUNCTION__, toolbar);

	[self incrementSearchHit];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar beginSearch:(nonnull NSString *)text
{
	//NSLog(@"%s %@ '%@'", __FUNCTION__, toolbar, text);

	[self beginTextSearch:text];
}

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar searchText:(nonnull NSString *)text
{
	//NSLog(@"%s %@ '%@'", __FUNCTION__, toolbar, text);

	[self newSearchText:text];
}

#pragma mark - UXReaderDocumentSearchDelegate methods

- (void)document:(nonnull UXReaderDocument *)document didBeginDocumentSearch:(NSUInteger)kind
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, document, kind);

	allSearchSelections = [[NSMutableArray alloc] init];

	pageSearchSelections = [[NSMutableDictionary alloc] init];

	[toolbarView showSearchBusy:YES];
}

- (void)document:(nonnull UXReaderDocument *)document didFinishDocumentSearch:(NSUInteger)total
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, document, total);

	[toolbarView showSearchBusy:NO];

	if (pageSearchSelections != nil)
	{
		if (total > 0) // Text was found
		{
			//[toolbarView showFoundCount:total];

			[toolbarView enableSearchControl:(total > 1)];

			[documentView setSearchSelections:pageSearchSelections];

			[self searchHitIncrementPage:NO]; // Show hits
		}
		else // Text was not found
		{
			[documentView setSearchSelections:nil];

			[toolbarView showSearchNotFound];
		}
	}
	else // Was cancelled
	{
		[documentView setSearchSelections:nil];
	}
}

- (void)document:(nonnull UXReaderDocument *)document didBeginPageSearch:(NSUInteger)page pages:(NSUInteger)pages
{
	//NSLog(@"%s %@ %lu %lu", __FUNCTION__, document, page, pages);

	//const NSRange range = NSMakeRange((page + 1), pages); [toolbarView showSearchRange:range];

	//[toolbarView showFoundCount:(page + 1)];
}

- (void)document:(nonnull UXReaderDocument *)document didFinishPageSearch:(NSUInteger)page total:(NSUInteger)total
{
	//NSLog(@"%s %@ %lu %lu", __FUNCTION__, document, page, total);

	[toolbarView showFoundCount:total];
}

- (void)document:(nonnull UXReaderDocument *)document searchDidMatch:(nonnull NSArray<UXReaderTextSelection *> *)selections page:(NSUInteger)page
{
	//NSLog(@"%s %@ %lu %@", __FUNCTION__, document, page, selections);

	if (pageSearchSelections != nil)
	{
		pageSearchSelections[@(page)] = selections;

		[allSearchSelections addObjectsFromArray:selections];
	}
}

#pragma mark - NSWindowDelegate methods

@end
