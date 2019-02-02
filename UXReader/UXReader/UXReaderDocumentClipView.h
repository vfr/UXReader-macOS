//
//	UXReaderDocumentClipView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol UXReaderDocumentClipViewDelegate <NSObject>

@optional // Delegate protocols

- (void)clipView:(nonnull __kindof NSClipView *)view boundsDidChange:(NSRect)bounds;

@end

@interface UXReaderDocumentClipView : NSClipView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderDocumentClipViewDelegate> delegate;

@end
