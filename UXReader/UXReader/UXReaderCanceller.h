//
//	UXReaderCanceller.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UXReaderCanceller : NSObject <NSObject>

- (void)cancel;

- (BOOL)isCancelled;

- (nonnull NSLock *)lock;

- (nonnull NSUUID *)uuid;

@end
