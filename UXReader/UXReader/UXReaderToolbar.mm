//
//	UXReaderToolbar.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderToolbar.h"
#import "UXReaderAppearance.h"

#import <QuartzCore/QuartzCore.h>

@interface UXReaderToolbar () <NSSearchFieldDelegate>

@end

@implementation UXReaderToolbar
{
	NSBundle *bundle;

	NSPopUpButton *viewButton;

	NSProgressIndicator *busyControl;

	NSLayoutConstraint *pageTextFieldWidth;

	NSNumberFormatter *pageValueFormatter;

	NSSegmentedControl *zoomControl;
	NSSegmentedControl *pageControl;
	NSSegmentedControl *findControl;

	NSSearchField *findSearchField;

	NSTextField *pageTextField;
	NSTextField *findTextLabel;

	NSFont *textFont;

	BOOL searchUI;
}

#pragma mark - Constants

#define ZOOM_DEC 0
#define ZOOM_FIT 1
#define ZOOM_INC 2

#define PAGE_DEC 0
#define PAGE_INC 1

#define FIND_DEC 0
#define FIND_INC 1

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UXReaderToolbar instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		self.translatesAutoresizingMaskIntoConstraints = NO; self.wantsLayer = YES;

		const CGFloat th = ([UXReaderAppearance toolbarHeight] + [UXReaderAppearance viewSeparatorHeight]);

		[self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
															toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:th]];

		bundle = [NSBundle bundleForClass:[self class]]; textFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]]; [self populate];
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);
}

- (BOOL)isOpaque
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

- (void)drawRect:(NSRect)rect
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(rect));

	const CGFloat sh = [UXReaderAppearance viewSeparatorHeight];

	NSRect lineRect = self.bounds; lineRect.size.height = sh;
	[[UXReaderAppearance viewSeparatorColor] set]; NSRectFill(lineRect);

	NSRect fillRect = self.bounds; fillRect.origin.y += sh; fillRect.size.height -= sh;
	[[UXReaderAppearance toolbarBackgroundColor] set]; NSRectFill(fillRect);
}

- (void)layout
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(self.bounds));

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout ", __FUNCTION__);
}

- (nonnull NSPopUpButton *)addViewButton
{
	//NSLog(@"%s", __FUNCTION__);

	NSMenuItem *menuItem = nil;

	NSMenu *menu = [[NSMenu alloc] init];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.image = [bundle imageForResource:@"Toolbar-Page-View"];
	menuItem.title = @""; // No title
	[menu addItem:menuItem];

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

	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
	button.translatesAutoresizingMaskIntoConstraints = NO; button.wantsLayer = YES;
	button.toolTip = [bundle localizedStringForKey:@"ViewOptionsToolTip" value:nil table:nil];
	button.bezelStyle = NSBezelStyleTexturedRounded; button.menu = menu; button.font = textFont;
	if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) [(NSPopUpButtonCell *)button.cell setArrowPosition:NSPopUpNoArrow];
	button.enabled = NO; //button.hidden = NO;
	[self addSubview:button];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return button;
}

- (nonnull NSSegmentedControl *)addZoomControl
{
	//NSLog(@"%s", __FUNCTION__);

	NSSegmentedControl *control = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect]; NSSegmentedCell *cell = control.cell;
	control.translatesAutoresizingMaskIntoConstraints = NO; control.wantsLayer = YES;
	control.ignoresMultiClick = NO; cell.trackingMode = NSSegmentSwitchTrackingMomentary;
	control.segmentStyle = NSSegmentStyleTexturedRounded; control.segmentCount = 3;
	control.target = self; control.action = @selector(zoomDocumentControl:);
	[control setImage:[bundle imageForResource:@"Toolbar-Zoom-Dec"] forSegment:ZOOM_DEC];
	[control setImage:[bundle imageForResource:@"Toolbar-Zoom-Fit"] forSegment:ZOOM_FIT];
	[control setImage:[bundle imageForResource:@"Toolbar-Zoom-Inc"] forSegment:ZOOM_INC];
	[cell setToolTip:[bundle localizedStringForKey:@"ZoomDecrementToolTip" value:nil table:nil] forSegment:ZOOM_DEC];
	[cell setToolTip:[bundle localizedStringForKey:@"ZoomFitAspectToolTip" value:nil table:nil] forSegment:ZOOM_FIT];
	[cell setToolTip:[bundle localizedStringForKey:@"ZoomIncrementToolTip" value:nil table:nil] forSegment:ZOOM_INC];
	[cell setEnabled:NO forSegment:ZOOM_DEC]; [cell setEnabled:NO forSegment:ZOOM_FIT]; [cell setEnabled:NO forSegment:ZOOM_INC];
	control.enabled = NO; //control.hidden = NO;
	[self addSubview:control];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:control attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return control;
}

- (nonnull NSSegmentedControl *)addPageControl
{
	//NSLog(@"%s", __FUNCTION__);

	NSSegmentedControl *control = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect]; NSSegmentedCell *pageCell = control.cell;
	control.translatesAutoresizingMaskIntoConstraints = NO; control.wantsLayer = YES;
	control.ignoresMultiClick = NO; pageCell.trackingMode = NSSegmentSwitchTrackingMomentary;
	control.segmentStyle = NSSegmentStyleTexturedRounded; control.segmentCount = 2;
	control.target = self; control.action = @selector(pageDocumentControl:);
	[control setImage:[bundle imageForResource:@"Toolbar-Page-Dec"] forSegment:PAGE_DEC];
	[control setImage:[bundle imageForResource:@"Toolbar-Page-Inc"] forSegment:PAGE_INC];
	[pageCell setToolTip:[bundle localizedStringForKey:@"PageDecrementToolTip" value:nil table:nil] forSegment:PAGE_DEC];
	[pageCell setToolTip:[bundle localizedStringForKey:@"PageIncrementToolTip" value:nil table:nil] forSegment:PAGE_INC];
	[pageCell setEnabled:NO forSegment:PAGE_DEC]; [pageCell setEnabled:NO forSegment:PAGE_INC];
	control.enabled = NO; //control.hidden = NO;
	[self addSubview:control];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:control attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return control;
}

- (nonnull NSTextField *)addPageTextField
{
	//NSLog(@"%s", __FUNCTION__);

	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle; formatter.allowsFloats = NO; pageValueFormatter = formatter;

	NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	textField.translatesAutoresizingMaskIntoConstraints = NO; textField.wantsLayer = YES;
	textField.toolTip = [bundle localizedStringForKey:@"GotoSomePageToolTip" value:nil table:nil];
	textField.alignment = NSTextAlignmentCenter; textField.formatter = formatter;
	textField.bezelStyle = NSTextFieldRoundedBezel; textField.font = textFont;
	textField.target = self; textField.action = @selector(gotoDocumentPage:);
	textField.enabled = NO; //textField.hidden = NO;
	[self addSubview:textField];

	pageTextFieldWidth = [NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
														toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:64.0];
	[textField addConstraint:pageTextFieldWidth];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return textField;
}

- (nonnull NSSearchField *)addFindSearchField
{
	//NSLog(@"%s", __FUNCTION__);

	NSMenuItem *menuItem = nil;

	NSMenu *menu = [[NSMenu alloc] init];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.title = [bundle localizedStringForKey:@"ToolbarRecentSearches" value:nil table:nil];
	menuItem.tag = NSSearchFieldRecentsMenuItemTag;
	[menu addItem:menuItem];

	menuItem = [NSMenuItem separatorItem];
	menuItem.tag = NSSearchFieldRecentsTitleMenuItemTag;
	[menu addItem:menuItem];

	menuItem = [[NSMenuItem alloc] init];
	menuItem.title = [bundle localizedStringForKey:@"ToolbarClearSearchList" value:nil table:nil];
	menuItem.tag = NSSearchFieldClearRecentsMenuItemTag;
	[menu addItem:menuItem];

	NSSearchField *searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
	searchField.translatesAutoresizingMaskIntoConstraints = NO; searchField.wantsLayer = YES;
	searchField.toolTip = [bundle localizedStringForKey:@"SearchDocumentToolTip" value:nil table:nil];
	searchField.bezelStyle = NSTextFieldRoundedBezel; searchField.font = textFont; searchField.delegate = self;
	//searchField.target = self; searchField.action = @selector(searchDocument:);
	NSSearchFieldCell *cell = searchField.cell; cell.searchMenuTemplate = menu;
	searchField.enabled = NO; //searchField.hidden = NO;
	[self addSubview:searchField];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:searchField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
														toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:256.0]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:searchField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return searchField;
}

- (nonnull NSSegmentedControl *)addFindControl
{
	//NSLog(@"%s", __FUNCTION__);

	NSSegmentedControl *control = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect]; NSSegmentedCell *cell = control.cell;
	control.translatesAutoresizingMaskIntoConstraints = NO; control.wantsLayer = YES;
	control.ignoresMultiClick = NO; cell.trackingMode = NSSegmentSwitchTrackingMomentary;
	control.segmentStyle = NSSegmentStyleTexturedRounded; control.segmentCount = 2;
	control.target = self; control.action = @selector(findDocumentControl:);
	[control setImage:[NSImage imageNamed:NSImageNameLeftFacingTriangleTemplate] forSegment:FIND_DEC];
	[control setImage:[NSImage imageNamed:NSImageNameRightFacingTriangleTemplate] forSegment:FIND_INC];
	[cell setToolTip:[bundle localizedStringForKey:@"FindDecrementToolTip" value:nil table:nil] forSegment:FIND_DEC];
	[cell setToolTip:[bundle localizedStringForKey:@"FindIncrementToolTip" value:nil table:nil] forSegment:FIND_INC];
	[cell setEnabled:NO forSegment:FIND_DEC]; [cell setEnabled:NO forSegment:FIND_INC];
	control.hidden = YES; control.alphaValue = 0.0;
	[self addSubview:control];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:control attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return control;
}

- (nonnull NSTextField *)addFindTextLabel
{
	//NSLog(@"%s", __FUNCTION__);

	NSTextField *textLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
	textLabel.translatesAutoresizingMaskIntoConstraints = NO; textLabel.wantsLayer = YES;
	textLabel.font = textFont; textLabel.bezeled = NO; textLabel.drawsBackground = NO;
	textLabel.editable = NO; textLabel.selectable = NO; textLabel.stringValue = @"-";
	textLabel.hidden = YES; textLabel.alphaValue = 0.0;
	[self addSubview:textLabel];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	return textLabel;
}

- (nonnull NSProgressIndicator *)addBusyControl
{
	//NSLog(@"%s", __FUNCTION__);

	NSProgressIndicator *control = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
	control.translatesAutoresizingMaskIntoConstraints = NO; control.wantsLayer = YES;
	control.style = NSProgressIndicatorSpinningStyle; control.controlSize = NSSmallControlSize; control.displayedWhenStopped = NO;
	[self addSubview:control];

	return control;
}

- (void)populate
{
	//NSLog(@"%s", __FUNCTION__);

	viewButton = [self addViewButton]; zoomControl = [self addZoomControl]; pageControl = [self addPageControl];

	pageTextField = [self addPageTextField]; findSearchField = [self addFindSearchField]; findControl = [self addFindControl];

	findTextLabel = [self addFindTextLabel]; busyControl = [self addBusyControl];

	const CGFloat space = [UXReaderAppearance toolbarItemSpace];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:viewButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:zoomControl attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:viewButton attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:pageControl attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:zoomControl attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:pageTextField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:pageControl attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:findSearchField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:pageTextField attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:findControl attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:findSearchField attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:findTextLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
														toItem:findControl attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:space]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:busyControl attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
														toItem:findControl attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];

	[self addConstraint:[NSLayoutConstraint constraintWithItem:busyControl attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
														toItem:findControl attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
}

- (void)enable:(BOOL)enable;
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	viewButton.enabled = enable; zoomControl.enabled = enable; pageControl.enabled = enable;

	pageTextField.enabled = enable; findSearchField.enabled = enable;
}

- (void)setPageCount:(NSUInteger)count
{
	//NSLog(@"%s %lu", __FUNCTION__, count);

	pageValueFormatter.minimum = [NSNumber numberWithUnsignedInteger:1];

	pageValueFormatter.maximum = [NSNumber numberWithUnsignedInteger:count];

	NSString *format = [bundle localizedStringForKey:@"PageOfPages" value:nil table:nil];

	NSString *text = [NSString stringWithFormat:format, count, count]; // Text to measure

	const NSSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : textFont}];

	const CGFloat tw = ceil(textSize.width + 33.0); pageTextFieldWidth.constant = tw;
}

- (void)buildKeyViewLoopWithView:(nonnull NSView *)view
{
	//NSLog(@"%s %@", __FUNCTION__, view);

	pageTextField.nextKeyView = findSearchField; findSearchField.nextKeyView = view; view.nextKeyView = pageTextField;
}

- (void)showPageNumber:(NSUInteger)page ofPages:(NSUInteger)pages
{
	//NSLog(@"%s %lu %lu", __FUNCTION__, page, pages);

	NSString *format = [bundle localizedStringForKey:@"PageOfPages" value:nil table:nil];

	NSTextFieldCell *textFieldCell = pageTextField.cell; pageTextField.stringValue = @"";

	textFieldCell.placeholderString = [NSString stringWithFormat:format, page, pages];
}

- (void)enableZoomDecrement:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *zoomCell = zoomControl.cell;

	[zoomCell setEnabled:enable forSegment:ZOOM_DEC];
}

- (void)enableZoomFitAspect:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *zoomCell = zoomControl.cell;

	[zoomCell setEnabled:enable forSegment:ZOOM_FIT];
}

- (void)enableZoomIncrement:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *zoomCell = zoomControl.cell;

	[zoomCell setEnabled:enable forSegment:ZOOM_INC];
}

- (void)enablePageDecrement:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *pageCell = pageControl.cell;

	[pageCell setEnabled:enable forSegment:PAGE_DEC];
}

- (void)enablePageIncrement:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *pageCell = pageControl.cell;

	[pageCell setEnabled:enable forSegment:PAGE_INC];
}

- (void)enableSearchControl:(BOOL)enable
{
	//NSLog(@"%s %i", __FUNCTION__, enable);

	NSSegmentedCell *findCell = findControl.cell;

	[findCell setEnabled:enable forSegment:FIND_DEC];
	[findCell setEnabled:enable forSegment:FIND_INC];
}

- (void)addRecentSearch:(nonnull NSString *)text
{
	//NSLog(@"%s '%@'", __FUNCTION__, text);

	NSMutableArray<NSString *> *list = [[findSearchField recentSearches] mutableCopy];

	[list removeObject:text]; [list insertObject:text atIndex:0]; [findSearchField setRecentSearches:list];
}

- (void)resetSearchUI
{
	//NSLog(@"%s", __FUNCTION__);

	[self enableSearchControl:NO]; findTextLabel.stringValue = @"";
}

- (void)showSearchUI:(BOOL)show
{
	//NSLog(@"%s %i", __FUNCTION__, show);

	if (show != searchUI)
	{
		searchUI = show; // New state

		if (searchUI == YES) // Show search views
		{
			findControl.hidden = NO; findTextLabel.hidden = NO;
		}

		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
		{
			context.allowsImplicitAnimation = YES; //context.duration = 0.25;
			context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

			const CGFloat a = (self->searchUI ? 1.0 : 0.0); self->findControl.alphaValue = a; self->findTextLabel.alphaValue = a;
		}
		completionHandler:^(void)
		{
			if (self->searchUI == NO) // Hide search views
			{
				self->findControl.hidden = YES; self->findTextLabel.hidden = YES;
			}
		}];
	}
}

- (void)showSearchBusy:(BOOL)show
{
	//NSLog(@"%s %i", __FUNCTION__, show);

	[findControl setEnabled:((show == YES) ? NO : YES)];

	if (show == YES) [busyControl startAnimation:nil]; else [busyControl stopAnimation:nil];
}

- (void)showFound:(NSUInteger)x of:(NSUInteger)n
{
	//NSLog(@"%s %lu %lu", __FUNCTION__, x, n);

	NSString *format = [bundle localizedStringForKey:@"SearchRangeCount" value:nil table:nil];

	findTextLabel.stringValue = [NSString stringWithFormat:format, x, n];
}

- (void)showFoundCount:(NSUInteger)count
{
	//NSLog(@"%s %lu", __FUNCTION__, count);

	NSString *format = [bundle localizedStringForKey:@"SearchFoundCount" value:nil table:nil];

	findTextLabel.stringValue = [NSString stringWithFormat:format, count];
}

- (void)showSearchNotFound
{
	//NSLog(@"%s", __FUNCTION__);

	NSString *text = [bundle localizedStringForKey:@"SearchNotFound" value:nil table:nil];

	findTextLabel.stringValue = text;
}

- (void)findTextFieldFocus
{
	//NSLog(@"%s", __FUNCTION__);

	if (findSearchField.acceptsFirstResponder == YES)
	{
		[self.window makeFirstResponder:findSearchField];
	}
}

- (void)gotoPageFieldFocus
{
	//NSLog(@"%s", __FUNCTION__);

	if (pageTextField.acceptsFirstResponder == YES)
	{
		[self.window makeFirstResponder:pageTextField];
	}
}

#pragma mark - NSSegmentedControl methods

- (void)zoomDocumentControl:(NSSegmentedControl *)control
{
	//NSLog(@"%s %@", __FUNCTION__, control);

	switch (control.selectedSegment)
	{
		case ZOOM_DEC: { [delegate toolbar:self zoomDecrement:nil]; break; }
		case ZOOM_FIT: { [delegate toolbar:self zoomFitAspect:nil]; break; }
		case ZOOM_INC: { [delegate toolbar:self zoomIncrement:nil]; break; }
	}
}

- (void)pageDocumentControl:(NSSegmentedControl *)control
{
	//NSLog(@"%s %@", __FUNCTION__, control);

	switch (control.selectedSegment)
	{
		case PAGE_DEC: { [delegate toolbar:self pageDecrement:nil]; break; }
		case PAGE_INC: { [delegate toolbar:self pageIncrement:nil]; break; }
	}
}

- (void)findDocumentControl:(NSSegmentedControl *)control
{
	//NSLog(@"%s %@", __FUNCTION__, control);

	switch (control.selectedSegment)
	{
		case FIND_DEC: { [delegate toolbar:self findDecrement:nil]; break; }
		case FIND_INC: { [delegate toolbar:self findIncrement:nil]; break; }
	}
}

#pragma mark - NSTextField methods

- (void)gotoDocumentPage:(NSTextField *)textField
{
	//NSLog(@"%s %@", __FUNCTION__, textField);

	const NSUInteger page = [textField integerValue];

	[delegate toolbar:self gotoPage:(page - 1)];
}

#pragma mark - NSTextFieldDelegate methods

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	//NSLog(@"%s %@", __FUNCTION__, notification);

	if (notification.object == findSearchField)
	{
		NSString *text = [findSearchField stringValue];

		[delegate toolbar:self beginSearch:text];
	}
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	//NSLog(@"%s %@", __FUNCTION__, notification);

	if (notification.object == findSearchField)
	{
		NSString *text = [findSearchField stringValue];

		[delegate toolbar:self searchText:text];
	}
}

@end
