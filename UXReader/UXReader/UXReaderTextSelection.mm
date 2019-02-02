//
//	UXReaderTextSelection.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderTextSelection.h"

@implementation UXReaderTextSelection
{
	__weak UXReaderDocument *document;

	NSUInteger unicharIndex, unicharCount;

	NSArray<NSValue *> *rectangles;

	NSUInteger page;

	BOOL highlight;
}

#pragma mark - UXReaderTextSelection class methods

+ (nullable instancetype)document:(nonnull UXReaderDocument *)document page:(NSUInteger)page index:(NSUInteger)index count:(NSUInteger)count rectangles:(nonnull NSArray<NSValue *> *)rectangles
{
	//NSLog(@"%s %@ %lu %lu %lu %@", __FUNCTION__, document, page, index, count, rectangles);

	return [[UXReaderTextSelection alloc] initWithDocument:document page:page index:index count:count rectangles:rectangles];
}

#pragma mark - UXReaderTextSelection instance methods

- (instancetype)init
{
	//NSLog(@"%s", __FUNCTION__);

	if ((self = [super init])) // Initialize superclass
	{
		page = NSUIntegerMax; unicharIndex = NSUIntegerMax;
	}

	return self;
}

- (nullable instancetype)initWithDocument:(nonnull UXReaderDocument *)documentx page:(NSUInteger)pagex index:(NSUInteger)index count:(NSUInteger)count rectangles:(nonnull NSArray<NSValue *> *)rects
{
	//NSLog(@"%s %@ %lu %lu %lu %@", __FUNCTION__, documentx, pagex, index, count, rects);

	if ((self = [self init])) // Initialize self
	{
		if ((documentx != nil) && ([rects count] > 0) && (count > 0))
		{
			document = documentx; page = pagex; rectangles = [rects copy];

			unicharIndex = index; unicharCount = count;
		}
		else // On failure
		{
			self = nil;
		}
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);
}

- (NSUInteger)page
{
	//NSLog(@"%s", __FUNCTION__);

	return page;
}

- (nullable NSArray<NSValue *> *)rectangles
{
	//NSLog(@"%s", __FUNCTION__);

	return rectangles;
}

- (NSString *)description
{
	//NSLog(@"%s", __FUNCTION__);

	return [NSString stringWithFormat:@"Page: %lu %@", page, rectangles];
}

- (void)setHighlight:(BOOL)state
{
	//NSLog(@"%s %i", __FUNCTION__, state);

	highlight = state;
}

- (BOOL)isHighlighted
{
	//NSLog(@"%s", __FUNCTION__);

	return highlight;
}

@end
