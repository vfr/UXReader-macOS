//
//	UXReaderAppearance.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UXReaderAppearance : NSObject <NSObject>

+ (NSSize)minimumWindowSize;

+ (CGFloat)verticalWindowInset;

+ (CGFloat)viewSeparatorHeight;

+ (CGFloat)toolbarHeight;

+ (CGFloat)toolbarItemSpace;

+ (CGFloat)pageSpaceGap;

+ (NSTimeInterval)searchBeginTimer;

+ (nonnull NSColor *)viewShadowColor;

+ (nonnull NSColor *)viewSeparatorColor;

+ (nonnull NSColor *)viewBackgroundColor;

+ (nonnull NSColor *)pageViewBackgroundColor;

+ (nonnull NSColor *)scrollViewBackgroundColor;

+ (nonnull NSColor *)toolbarBackgroundColor;

@end
