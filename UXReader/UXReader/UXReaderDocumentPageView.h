//
//	UXReaderDocumentPageView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderDocumentPageView;

@protocol UXReaderDocumentPageViewDelegate <NSObject>

@required // Delegate protocols

@end

@interface UXReaderDocumentPageView : NSView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderDocumentPageViewDelegate> delegate;

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)document page:(NSUInteger)page;

@property (nullable, weak, nonatomic, readwrite) NSLayoutConstraint *layoutConstraintX;
@property (nullable, weak, nonatomic, readwrite) NSLayoutConstraint *layoutConstraintY;

- (NSUInteger)page;

- (NSSize)pageSize;

@end
