//
//	UXReaderAppearance.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderAppearance.h"

@implementation UXReaderAppearance

#pragma mark - UXReaderAppearance class methods

+ (NSSize)minimumWindowSize
{
	return NSMakeSize(768.0, 640.0);
}

+ (CGFloat)verticalWindowInset
{
	return 8.0; // Points
}

+ (CGFloat)viewSeparatorHeight
{
	return 1.0; // Points
}

+ (CGFloat)toolbarHeight
{
	return 34.0; // Points
}

+ (CGFloat)toolbarItemSpace
{
	return 8.0; // Points
}

+ (CGFloat)pageSpaceGap
{
	return 2.0; // Points
}

+ (NSTimeInterval)searchBeginTimer
{
	return 2.0; // Seconds
}

+ (nonnull NSColor *)viewShadowColor
{
	return [NSColor colorWithGenericGamma22White:0.0 alpha:0.8];
}

+ (nonnull NSColor *)viewSeparatorColor
{
	return [NSColor colorWithGenericGamma22White:0.72 alpha:1.0];
}

+ (nonnull NSColor *)viewBackgroundColor
{
	return [NSColor colorWithGenericGamma22White:0.96 alpha:1.0];
}

+ (nonnull NSColor *)pageViewBackgroundColor
{
	return [NSColor colorWithGenericGamma22White:1.00 alpha:1.0];
}
	
+ (nonnull NSColor *)scrollViewBackgroundColor
{
	return [NSColor colorWithGenericGamma22White:0.50 alpha:1.0];
}

+ (nonnull NSColor *)toolbarBackgroundColor
{
	return [NSColor colorWithGenericGamma22White:0.86 alpha:1.0];
}

@end
