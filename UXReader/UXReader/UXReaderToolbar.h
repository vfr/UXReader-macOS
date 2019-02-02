//
//	UXReaderToolbar.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "UXReaderDefines.h"

@class UXReaderToolbar;

@protocol UXReaderToolbarDelegate <NSObject>

@required // Delegate protocols

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar gotoPage:(NSUInteger)page;

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomFitAspect:(nullable id)object;
- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomDecrement:(nullable id)object;
- (void)toolbar:(nonnull UXReaderToolbar *)toolbar zoomIncrement:(nullable id)object;

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar pageDecrement:(nullable id)object;
- (void)toolbar:(nonnull UXReaderToolbar *)toolbar pageIncrement:(nullable id)object;

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar findDecrement:(nullable id)object;
- (void)toolbar:(nonnull UXReaderToolbar *)toolbar findIncrement:(nullable id)object;

- (void)toolbar:(nonnull UXReaderToolbar *)toolbar beginSearch:(nonnull NSString *)text;
- (void)toolbar:(nonnull UXReaderToolbar *)toolbar searchText:(nonnull NSString *)text;

@end

@interface UXReaderToolbar : NSView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderToolbarDelegate> delegate;

- (void)enable:(BOOL)enable;

- (void)setPageCount:(NSUInteger)count;

- (void)buildKeyViewLoopWithView:(nonnull NSView *)view;

- (void)showPageNumber:(NSUInteger)page ofPages:(NSUInteger)pages;

- (void)enableZoomDecrement:(BOOL)enable;
- (void)enableZoomFitAspect:(BOOL)enable;
- (void)enableZoomIncrement:(BOOL)enable;

- (void)enablePageDecrement:(BOOL)enable;
- (void)enablePageIncrement:(BOOL)enable;

- (void)enableSearchControl:(BOOL)enable;

- (void)addRecentSearch:(nonnull NSString *)text;

- (void)resetSearchUI;
- (void)showSearchUI:(BOOL)show;
- (void)showSearchBusy:(BOOL)show;
- (void)showFound:(NSUInteger)x of:(NSUInteger)n;
- (void)showFoundCount:(NSUInteger)count;
- (void)showSearchNotFound;

- (void)findTextFieldFocus;
- (void)gotoPageFieldFocus;

@end
