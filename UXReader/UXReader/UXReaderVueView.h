//
//	UXReaderVueView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderVueView;

@protocol UXReaderVueViewDelegate <NSObject>

@required // Delegate protocols

@end

@interface UXReaderVueView : NSView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderVueViewDelegate> delegate;

@end
