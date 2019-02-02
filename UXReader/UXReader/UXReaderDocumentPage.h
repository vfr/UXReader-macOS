//
//	UXReaderDocumentPage.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderCanceller;
@class UXReaderTextSelection;

@interface UXReaderDocumentPage : NSObject <NSObject>

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)document page:(NSUInteger)page;

- (nonnull void *)pdfPage;
- (nonnull void *)textPage;

- (NSUInteger)page;
- (NSUInteger)rotation;
- (NSSize)pageSize;

- (NSPoint)convertViewPointToPage:(NSPoint)point;
- (NSRect)convertFromPageX1:(CGFloat)x1 Y1:(CGFloat)y1 X2:(CGFloat)x2 Y2:(CGFloat)y2;

- (void)renderTileInContext:(nonnull CGContextRef)context view:(nonnull NSView *)view;

- (void)thumbWithSize:(NSSize)size canceller:(nonnull UXReaderCanceller *)canceller completion:(nonnull void (^)(NSImage *_Nonnull thumb))handler;

- (void)setSearchSelections:(nullable NSArray<UXReaderTextSelection *> *)selections;
- (nullable NSArray<UXReaderTextSelection *> *)searchSelections;

@end
