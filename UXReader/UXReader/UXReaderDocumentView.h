//
//	UXReaderDocumentView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "UXReaderDefines.h"

@class UXReaderDocument;
@class UXReaderDocumentView;
@class UXReaderTextSelection;

@protocol UXReaderDocumentViewDelegate <NSObject>

@optional // Delegate protocols

- (void)documentView:(nonnull UXReaderDocumentView *)view didChangePage:(NSUInteger)page;
- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeDocument:(nullable UXReaderDocument *)document;
- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeMode:(UXReaderDisplayMode)mode;
- (void)documentView:(nonnull UXReaderDocumentView *)view didChangeZoom:(CGFloat)value;

@end

@interface UXReaderDocumentView : NSScrollView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderDocumentViewDelegate> delegate;

- (nullable UXReaderDocument *)document;
- (void)setDocument:(nullable UXReaderDocument *)document;
- (BOOL)hasDocument:(nullable UXReaderDocument *)document;

- (void)setSelection:(nonnull UXReaderTextSelection *)selection;
- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections;
- (void)gotoSelection:(nonnull UXReaderTextSelection *)selection;

- (void)setDisplayMode:(UXReaderDisplayMode)mode;
- (UXReaderDisplayMode)displayMode;

- (NSUInteger)pageCount;
- (NSUInteger)currentPage;
- (void)gotoPage:(NSUInteger)page;
- (void)decrementPage;
- (BOOL)canDecrementPage;
- (void)incrementPage;
- (BOOL)canIncrementPage;

- (void)decrementZoom;
- (BOOL)canDecrementZoom;
- (void)incrementZoom;
- (BOOL)canIncrementZoom;
- (void)zoomFitWidth;
- (BOOL)canZoomFitWidth;
- (void)zoomFitHeight;
- (BOOL)canZoomFitHeight;
- (void)zoomOneToOne;
- (BOOL)canZoomOneToOne;

@end
