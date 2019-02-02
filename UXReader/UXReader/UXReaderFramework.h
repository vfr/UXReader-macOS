//
//	UXReaderFramework.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UXReaderFramework : NSObject <NSObject>

+ (nullable instancetype)sharedInstance; // Singleton

+ (void)dispatch_sync_on_work_queue:(nonnull dispatch_block_t)block;

+ (void)dispatch_async_on_work_queue:(nonnull dispatch_block_t)block;

+ (void)saveContextAsPNG:(nonnull CGContextRef)context;

+ (BOOL)prioritizePerformance;

@end

CG_INLINE CGRect UXRectScale(CGRect rect, const CGFloat sx, const CGFloat sy)
{
	rect.origin.x *= sx; rect.size.width *= sx; rect.origin.y *= sy; rect.size.height *= sy; return rect;
}

CG_INLINE CGSize UXSizeScale(CGSize size, const CGFloat sx, const CGFloat sy)
{
	size.width *= sx; size.height *= sy; return size;
}

CG_INLINE CGSize UXSizeFloor(CGSize size)
{
	size.width = floor(size.width); size.height = floor(size.height); return size;
}

CG_INLINE CGSize UXSizeSwap(const CGSize size)
{
	CGSize swap; swap.width = size.height; swap.height = size.width; return swap;
}

CG_INLINE CGSize UXAspectFitInSize(CGFloat max, CGSize size)
{
	const CGFloat ws = (max / size.width); const CGFloat hs = (max / size.height); const CGFloat ts = ((ws < hs) ? ws : hs);

	const CGFloat tw = floor(size.width * ts); const CGFloat th = floor(size.height * ts); return CGSizeMake(tw, th);
}
