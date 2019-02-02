//
//	UXReaderCanceller.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderCanceller.h"

@implementation UXReaderCanceller
{
	NSLock *lock;

	NSUUID *uuid;

	BOOL cancel;
}

#pragma mark - UXReaderCanceller instance methods

- (instancetype)init
{
	//NSLog(@"%s", __FUNCTION__);

	if ((self = [super init])) // Initialize superclass
	{
		lock = [[NSLock alloc] init]; uuid = [[NSUUID alloc] init];
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);
}

- (void)cancel
{
	//NSLog(@"%s", __FUNCTION__);

	cancel = YES;
}

- (BOOL)isCancelled
{
	//NSLog(@"%s", __FUNCTION__);

	return cancel;
}

- (nonnull NSLock *)lock
{
	//NSLog(@"%s", __FUNCTION__);

	return lock;
}

- (nonnull NSUUID *)uuid
{
	//NSLog(@"%s", __FUNCTION__);

	return uuid;
}

@end
