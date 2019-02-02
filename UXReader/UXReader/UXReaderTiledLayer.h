//
//	UXReaderTiledLayer.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface UXReaderTiledLayer : CATiledLayer

+ (CGFloat)minimumZoom;
+ (CGFloat)maximumZoom;

@end
