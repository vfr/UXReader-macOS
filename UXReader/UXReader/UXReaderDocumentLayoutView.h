//
//	UXReaderDocumentLayoutView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "UXReaderDefines.h"

@class UXReaderDocument;
@class UXReaderDocumentLayoutView;
@class UXReaderTextSelection;

@protocol UXReaderDocumentLayoutViewDelegate <NSObject>

@optional // Delegate protocols

- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangePage:(NSUInteger)page;
- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangeDocument:(nullable UXReaderDocument *)document;
- (void)layoutView:(nonnull UXReaderDocumentLayoutView *)view didChangeMode:(UXReaderDisplayMode)mode;

@required // Delegate protocols

- (void)scrollDecrementLineX;
- (void)scrollDecrementLineY;
- (void)scrollIncrementLineX;
- (void)scrollIncrementLineY;

- (void)scrollDecrementPageX;
- (void)scrollDecrementPageY;
- (void)scrollIncrementPageX;
- (void)scrollIncrementPageY;

- (void)scrollMinimumUsableX;
- (void)scrollMinimumUsableY;
- (void)scrollMaximumUsableX;
- (void)scrollMaximumUsableY;

@end

@interface UXReaderDocumentLayoutView : NSView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderDocumentLayoutViewDelegate> delegate;

- (nullable UXReaderDocument *)document;
- (void)setDocument:(nullable UXReaderDocument *)document;

- (void)setSelection:(nonnull UXReaderTextSelection *)selection;
- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections;
- (void)gotoSelection:(nonnull UXReaderTextSelection *)selection;

- (void)setDisplayMode:(UXReaderDisplayMode)mode;
- (UXReaderDisplayMode)displayMode;

- (NSUInteger)pageCount;
- (NSUInteger)currentPage;
- (BOOL)isShowingPages;
- (void)gotoPage:(NSUInteger)page;
- (void)decrementPage;
- (BOOL)canDecrementPage;
- (void)incrementPage;
- (BOOL)canIncrementPage;

- (void)visibleRectDidChange;

@end
