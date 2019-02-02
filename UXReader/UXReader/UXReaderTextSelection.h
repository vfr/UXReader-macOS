//
//	UXReaderTextSelection.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderDocument;

@interface UXReaderTextSelection : NSObject <NSObject>

+ (nullable instancetype)document:(nonnull UXReaderDocument *)document page:(NSUInteger)page index:(NSUInteger)index count:(NSUInteger)count rectangles:(nonnull NSArray<NSValue *> *)rectangles;

- (NSUInteger)page;

- (nullable NSArray<NSValue *> *)rectangles;

- (void)setHighlight:(BOOL)state;
- (BOOL)isHighlighted;

@end
