//
//	UXReaderPaneView.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderPaneView;

@protocol UXReaderPaneViewDelegate <NSObject>

@required // Delegate protocols

@end

@interface UXReaderPaneView : NSView

@property (nullable, weak, nonatomic, readwrite) id <UXReaderPaneViewDelegate> delegate;

@end
