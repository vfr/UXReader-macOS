//
//	UXReaderDocumentPage.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocument.h"
#import "UXReaderDocumentPage.h"
#import "UXReaderTextSelection.h"
#import "UXReaderCanceller.h"
#import "UXReaderFramework.h"

#import "fpdfview.h"
#import "fpdf_text.h"
#import "fpdf_edit.h"

@interface UXReaderDocumentPage ()

@end

@implementation UXReaderDocumentPage
{
	FPDF_DOCUMENT pdfDocument;

	__strong UXReaderDocument *document;

	FPDF_PAGE pdfPage; FPDF_TEXTPAGE textPage;

	NSArray<UXReaderTextSelection *> *searchSelections;

	NSUInteger page; NSSize pageSize;

	NSUInteger rotation;
}

#pragma mark - UXReaderDocumentPage instance methods

- (instancetype)init
{
	//NSLog(@"%s", __FUNCTION__);

	if ((self = [super init])) // Initialize superclass
	{
		page = NSUIntegerMax;
	}

	return self;
}

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)documentx page:(NSUInteger)pagex
{
	//NSLog(@"%s %@ %lu", __FUNCTION__, documentx, pagex);

	if ((self = [self init])) // Initialize self
	{
		if ((documentx != nil) && (pagex < [documentx pageCount])) // Carry on
		{
			page = pagex; document = documentx; pdfDocument = [document pdfDocument];

			if ([self loadPage] == YES) [self metadata]; else self = nil;
		}
		else // On error
		{
			self = nil;
		}
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	[UXReaderFramework dispatch_sync_on_work_queue:
	^{
		if (self->textPage != nil) { FPDFText_ClosePage(self->textPage); self->textPage = nil; };

		if (self->pdfPage != nil) { FPDF_ClosePage(self->pdfPage); self->pdfPage = nil; }
	}];
}

- (BOOL)loadPage
{
	//NSLog(@"%s", __FUNCTION__);

	[UXReaderFramework dispatch_sync_on_work_queue:
	^{
		if ((self->pdfPage = FPDF_LoadPage(self->pdfDocument, int(self->page))))
		{
			self->rotation = FPDFPage_GetRotation(self->pdfPage); // Angle

			if ((self->textPage = FPDFText_LoadPage(self->pdfPage)))
			{
				// ...
			}
		}
	}];

	return ((textPage != nil) && (pdfPage != nil));
}

- (void)metadata
{
	//NSLog(@"%s", __FUNCTION__);

	pageSize = [document pageSize:page]; // Already rotated

	searchSelections = [document searchSelections][@(page)];
}

- (nonnull void *)pdfPage
{
	//NSLog(@"%s", __FUNCTION__);

	return pdfPage;
}

- (nonnull void *)textPage
{
	//NSLog(@"%s", __FUNCTION__);

	return textPage;
}

- (NSUInteger)page
{
	//NSLog(@"%s", __FUNCTION__);

	return page;
}

- (NSUInteger)rotation
{
	//NSLog(@"%s", __FUNCTION__);

	return rotation;
}

- (NSSize)pageSize
{
	//NSLog(@"%s", __FUNCTION__);

	return pageSize;
}

- (NSPoint)convertViewPointToPage:(NSPoint)point
{
	//NSLog(@"%s %@", __FUNCTION__, NSStringFromPoint(point));

	const CGFloat pw = pageSize.width; const CGFloat ph = pageSize.height;

	switch (rotation) // Page rotation
	{
		case 0: // 0 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(0.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(0.0, 0.0);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			//static const CGAffineTransform m = {1.0, 0.0, 0.0, 1.0, 0.0, 0.0};
			//point = CGPointApplyAffineTransform(point, m);
			break;
		}

		case 1: // 90 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(90.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(ph, 0.0);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {0.0, 1.0, -1.0, 0.0, ph, 0.0};
			point = CGPointApplyAffineTransform(point, m);
			break;
		}

		case 2: // 180 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(180.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(pw, ph);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {-1.0, 0.0, 0.0, -1.0, pw, ph};
			point = CGPointApplyAffineTransform(point, m);
			break;
		}

		case 3: // 270 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(270.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(0.0, pw);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {0.0, -1.0, 1.0, 0.0, 0.0, pw};
			point = CGPointApplyAffineTransform(point, m);
			break;
		}
	}

	return point;
}

- (NSRect)convertFromPageX1:(CGFloat)xp1 Y1:(CGFloat)yp1 X2:(CGFloat)xp2 Y2:(CGFloat)yp2
{
	//NSLog(@"%s x1: %g y1: %g x2: %g y2: %g", __FUNCTION__, xp1, yp1, xp2, yp2);

	CGFloat xr1 = xp1; CGFloat yr1 = yp1; CGFloat xr2 = xp2; CGFloat yr2 = yp2;

	const CGFloat pw = pageSize.width; const CGFloat ph = pageSize.height;

	switch (rotation) // Page rotation
	{
		case 0: // 0 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(0.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(0.0, 0.0);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			//static const CGAffineTransform m = {1.0, 0.0, 0.0, 1.0, 0.0, 0.0};
			//NSPoint pt1 = NSMakePoint(xp1, yp1); pt1 = CGPointApplyAffineTransform(pt1, m);
			//NSPoint pt2 = NSMakePoint(xp2, yp2); pt2 = CGPointApplyAffineTransform(pt2, m);
			//xr1 = pt1.x; yr1 = pt1.y; xr2 = pt2.x; yr2 = pt2.y;
			break;
		}

		case 1: // 90 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(-90.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(0.0, ph);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {0.0, -1.0, 1.0, 0.0, 0.0, ph};
			NSPoint pt1 = NSMakePoint(xp1, yp1); pt1 = CGPointApplyAffineTransform(pt1, m);
			NSPoint pt2 = NSMakePoint(xp2, yp2); pt2 = CGPointApplyAffineTransform(pt2, m);
			xr1 = pt1.x; yr1 = pt2.y; xr2 = pt2.x; yr2 = pt1.y;
			break;
		}

		case 2: // 180 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(-180.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(pw, ph);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {-1.0, 0.0, 0.0, -1.0, pw, ph};
			NSPoint pt1 = NSMakePoint(xp1, yp1); pt1 = CGPointApplyAffineTransform(pt1, m);
			NSPoint pt2 = NSMakePoint(xp2, yp2); pt2 = CGPointApplyAffineTransform(pt2, m);
			xr1 = pt2.x; yr1 = pt2.y; xr2 = pt1.x; yr2 = pt1.y;
			break;
		}

		case 3: // 270 degrees
		{
			//CGAffineTransform s = CGAffineTransformMakeScale(1.0, 1.0);
			//CGAffineTransform r = CGAffineTransformMakeRotation(-270.0 * M_PI / 180.0);
			//CGAffineTransform t = CGAffineTransformMakeTranslation(pw, 0.0);
			//CGAffineTransform m = CGAffineTransformConcat(CGAffineTransformConcat(s, r), t);
			static const CGAffineTransform m = {0.0, 1.0, -1.0, 0.0, pw, 0.0};
			NSPoint pt1 = NSMakePoint(xp1, yp1); pt1 = CGPointApplyAffineTransform(pt1, m);
			NSPoint pt2 = NSMakePoint(xp2, yp2); pt2 = CGPointApplyAffineTransform(pt2, m);
			xr1 = pt2.x; yr1 = pt1.y; xr2 = pt1.x; yr2 = pt2.y;
			break;
		}
	}

	return NSMakeRect(xr1, yr1, (xr2 - xr1), (yr2 - yr1));
}

- (void)renderTileInContext:(nonnull CGContextRef)context view:(nonnull NSView *)view
{
	//NSLog(@"%s %p %@", __FUNCTION__, context, view);

	if ((context == nil) || (view == nil)) return;

	[UXReaderFramework dispatch_sync_on_work_queue:
	^{
		const CGRect rect = CGContextGetClipBoundingBox(context);

		const CGRect device = CGContextConvertRectToDeviceSpace(context, rect);

		const CGFloat ys = (device.size.height / rect.size.height);

		const CGFloat xs = (device.size.width / rect.size.width);

		const CGRect area = UXRectScale(rect, xs, ys); // Zoom + device scale

		const CGColorSpaceRef rgb = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

		const CGBitmapInfo bmi = (kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast); // RBGx

		if (CGContextRef bmc = CGBitmapContextCreate(NULL, area.size.width, area.size.height, 8, 0, rgb, bmi))
		{
			const size_t bw = CGBitmapContextGetWidth(bmc); const size_t bh = CGBitmapContextGetHeight(bmc);

			CGContextSetRGBFillColor(bmc, 1.0, 1.0, 1.0, 1.0); CGContextFillRect(bmc, CGRectMake(0.0, 0.0, bw, bh));

			const size_t bpr = CGBitmapContextGetBytesPerRow(bmc); void *data = CGBitmapContextGetData(bmc);

			if (FPDF_BITMAP pdfBitmap = FPDFBitmap_CreateEx(int(bw), int(bh), FPDFBitmap_BGRx, data, int(bpr)))
			{
				const int options = (FPDF_REVERSE_BYTE_ORDER | FPDF_NO_CATCH | FPDF_ANNOT); // Tile render options

				const FS_MATRIX matrix = {float(xs), 0.0, 0.0, float(ys), float(-area.origin.x), float(-area.origin.y)};

				const FS_RECTF clip = {0.0, 0.0, float(bw), float(bh)}; // Clip to bitmap dimensions

				FPDF_RenderPageBitmapWithMatrix(pdfBitmap, self->pdfPage, &matrix, &clip, options);

				if (CGImageRef image = CGBitmapContextCreateImage(bmc))
				{
					CGContextSaveGState(context); // Save context

					CGContextScaleCTM(context, 1.0, -1.0); // Flip Y

					CGContextTranslateCTM(context, 0.0, -rect.size.height);

					CGRect flip = rect; flip.origin.y = -flip.origin.y;

					CGContextDrawImage(context, flip, image);

					CGContextRestoreGState(context);

					CGImageRelease(image);
				}

				FPDFBitmap_Destroy(pdfBitmap);
			}

			CGContextRelease(bmc);
		}

		CGColorSpaceRelease(rgb);
	}];

	if (searchSelections != nil) // Draw selections
	{
		const CGRect clip = CGContextGetClipBoundingBox(context);

		for (UXReaderTextSelection *selection in searchSelections)
		{
			for (NSValue *value in [selection rectangles])
			{
				const NSRect rect = [value rectValue];

				if (NSIntersectsRect(rect, clip) == YES)
				{
					if ([selection isHighlighted] == YES)
						CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.2);
					else
						CGContextSetRGBFillColor(context, 1.0, 1.0, 0.0, 0.3);

					CGContextFillRect(context, rect);
				}
			}
		}
	}
}

- (void)thumbWithSize:(NSSize)size canceller:(nonnull UXReaderCanceller *)canceller completion:(nonnull void (^)(NSImage *_Nonnull thumb))handler
{
	//NSLog(@"%s %@ %@ %p", __FUNCTION__, NSStringFromSize(size), canceller, handler);

	if ((canceller == nil) || (handler == nil)) return;

	[UXReaderFramework dispatch_async_on_work_queue:
	^{
		if ([canceller isCancelled] == YES) return; // Is cancelled

		const CGFloat tw = size.width; const CGFloat xs = (tw / self->pageSize.width);

		const CGFloat th = size.height; const CGFloat ys = (th / self->pageSize.height);

		const CGColorSpaceRef rgb = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

		const CGBitmapInfo bmi = (kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast);

		if (CGContextRef bmc = CGBitmapContextCreate(NULL, tw, th, 8, 0, rgb, bmi)) // Render thumb
		{
			const size_t bw = CGBitmapContextGetWidth(bmc); const size_t bh = CGBitmapContextGetHeight(bmc);

			CGContextSetRGBFillColor(bmc, 1.0, 1.0, 1.0, 1.0); CGContextFillRect(bmc, CGRectMake(0.0, 0.0, bw, bh));

			const size_t bpr = CGBitmapContextGetBytesPerRow(bmc); void *data = CGBitmapContextGetData(bmc);

			if (FPDF_BITMAP pdfBitmap = FPDFBitmap_CreateEx(int(bw), int(bh), FPDFBitmap_BGRx, data, int(bpr)))
			{
				const int options = (FPDF_REVERSE_BYTE_ORDER | FPDF_NO_CATCH | FPDF_ANNOT);

				FS_MATRIX matrix = {float(xs), 0.0, 0.0, float(-ys), 0.0, float(bh)};

				FS_RECTF clip = {0.0, 0.0, float(bw), float(bh)}; // Clip to bitmap

				FPDF_RenderPageBitmapWithMatrix(pdfBitmap, self->pdfPage, &matrix, &clip, options);

				if (CGImageRef image = CGBitmapContextCreateImage(bmc)) // Create NSImage
				{
					if (NSImage *thumb = [[NSImage alloc] initWithCGImage:image size:size])
					{
						if ([canceller isCancelled] == NO)
						{
							dispatch_async(dispatch_get_main_queue(),
							^{
								if ([canceller isCancelled] == NO) handler(thumb);
							});
						}
					}

					CGImageRelease(image);
				}

				FPDFBitmap_Destroy(pdfBitmap);
			}

			CGContextRelease(bmc);
		}

		CGColorSpaceRelease(rgb);
	}];
}

- (void)setSearchSelections:(nullable NSArray<UXReaderTextSelection *> *)selections
{
	//NSLog(@"%s %@", __FUNCTION__, selections);

	searchSelections = selections;
}

- (nullable NSArray<UXReaderTextSelection *> *)searchSelections
{
	//NSLog(@"%s", __FUNCTION__);

	return searchSelections;
}

@end
