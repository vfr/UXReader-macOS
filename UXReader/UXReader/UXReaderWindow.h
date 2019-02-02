//
//	UXReaderWindow.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderDocument;

@interface UXReaderWindow : NSWindow

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)document;

- (BOOL)hasDocument:(nonnull UXReaderDocument *)document;

- (IBAction)readerGotoPage:(nullable id)sender;
- (IBAction)readerDecrementPage:(nullable id)sender;
- (IBAction)readerIncrementPage:(nullable id)sender;

- (IBAction)readerDecrementZoom:(nullable id)sender;
- (IBAction)readerIncrementZoom:(nullable id)sender;
- (IBAction)readerZoomFitWidth:(nullable id)sender;
- (IBAction)readerZoomFitHeight:(nullable id)sender;
- (IBAction)readerZoomOneToOne:(nullable id)sender;

- (IBAction)readerFindText:(nullable id)sender;
- (IBAction)readerDecrementFind:(nullable id)sender;
- (IBAction)readerIncrementFind:(nullable id)sender;

- (IBAction)readerModeSinglePageStatic:(nullable id)sender;
- (IBAction)readerModeSinglePageScroll:(nullable id)sender;
- (IBAction)readerModeDoublePageStatic:(nullable id)sender;
- (IBAction)readerModeDoublePageScroll:(nullable id)sender;

@end
