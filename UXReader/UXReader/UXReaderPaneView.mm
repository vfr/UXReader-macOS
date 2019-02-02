//
//	UXReaderPaneView.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderPaneView.h"
#import "UXReaderAppearance.h"

@interface UXReaderPaneView ()

@end

@implementation UXReaderPaneView
{
}

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UXReaderPaneView instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		self.translatesAutoresizingMaskIntoConstraints = NO; self.wantsLayer = YES;
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);
}

/*
- (NSSize)intrinsicContentSize
{
	//NSLog(@"%s", __FUNCTION__);

	return NSMakeSize(NSViewNoInstrinsicMetric, NSViewNoInstrinsicMetric);
}
*/

- (void)layout
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(self.bounds));

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout ", __FUNCTION__);
}

- (BOOL)isOpaque
{
	//NSLog(@"%s", __FUNCTION__);

	return YES;
}

- (void)drawRect:(NSRect)rect
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(rect));

	if (self.subviews.count == 0) { [[UXReaderAppearance viewBackgroundColor] set]; NSRectFill(rect); }
}

@end
