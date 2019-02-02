//
//	UXReaderDocumentClipView.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocumentClipView.h"

@implementation UXReaderDocumentClipView

#pragma mark - Properties

@synthesize delegate;

#pragma mark - NSClipView instance methods

- (instancetype)initWithFrame:(NSRect)frame
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(frame));

	if ((self = [super initWithFrame:frame])) // Initialize superclass
	{
		//self.translatesAutoresizingMaskIntoConstraints = NO; //self.wantsLayer = YES;

		self.postsBoundsChangedNotifications = YES; NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

		[defaultCenter addObserver:self selector:@selector(clipViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:self];
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:self];
}

- (void)layout
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(self.bounds));

	[super layout]; if (self.hasAmbiguousLayout) NSLog(@"%s hasAmbiguousLayout", __FUNCTION__);
}

- (NSPoint)constrainScrollPoint_10_8:(NSPoint)newOrigin
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromPoint(newOrigin));

	const NSSize clipViewSize = self.bounds.size;
	const NSSize documentViewSize = self.documentView.frame.size;

	const CGFloat maxY = (documentViewSize.height - clipViewSize.height);
	const CGFloat maxX = (documentViewSize.width - clipViewSize.width);

	if (documentViewSize.height < clipViewSize.height)
		newOrigin.y = round(maxY * 0.5);
	else
		newOrigin.y = round(MAX(0.0, MIN(newOrigin.y, maxY)));

	if (documentViewSize.width < clipViewSize.width)
		newOrigin.x = round(maxX * 0.5);
	else
		newOrigin.x = round(MAX(0.0, MIN(newOrigin.x, maxX)));

	return newOrigin;
}

- (NSRect)constrainBoundsRect:(NSRect)proposedBounds
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromRect(proposedBounds));

	NSRect constrainedBounds = [super constrainBoundsRect:proposedBounds];

	if (self.documentView != nil) // Center document view
	{
		const NSSize documentViewSize = self.documentView.frame.size;

		if (proposedBounds.size.height > documentViewSize.height) // Center vertically
		{
			constrainedBounds.origin.y = round((documentViewSize.height - proposedBounds.size.height) * 0.5);
		}

		if (proposedBounds.size.width > documentViewSize.width) // Center horizontally
		{
			constrainedBounds.origin.x = round((documentViewSize.width - proposedBounds.size.width) * 0.5);
		}
	}

	return constrainedBounds;
}

#pragma mark - NSNotification methods

- (void)clipViewBoundsDidChange:(nonnull NSNotification *)notification
{
	//NSLog(@"%s %@", __FUNCTION__, notification);

	if (notification.object == self) // UXReaderDocumentClipView
	{
		if ([delegate respondsToSelector:@selector(clipView:boundsDidChange:)])
		{
			[delegate clipView:self boundsDidChange:[self bounds]];
		}
	}
}

@end
