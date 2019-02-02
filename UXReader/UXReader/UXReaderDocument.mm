//
//	UXReaderDocument.mm
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import "UXReaderDocument.h"
#import "UXReaderDocumentPage.h"
#import "UXReaderTextSelection.h"
#import "UXReaderAppearance.h"
#import "UXReaderFramework.h"
#import "UXReaderCanceller.h"

#import "fpdfview.h"
#import "fpdf_text.h"

@interface UXReaderDocument () <UXReaderDocumentDataSource>

@end

@implementation UXReaderDocument
{
	NSURL *documentURL; NSData *documentData;

	__weak id <UXReaderDocumentDataSource> dataSource;

	NSMapTable<NSNumber *, UXReaderDocumentPage *> *documentPages;

	NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *searchSelections;

	NSMutableDictionary<NSNumber *, NSValue *> *pageSizes;

	NSUInteger pageCount; NSString *title;

	UXReaderCanceller *searchCanceller;

	FPDF_DOCUMENT pdfDocument;

	BOOL prioritizePerformance;
}

#pragma mark - Properties

@synthesize search;

#pragma mark - UXReaderDocument functions

static int GetDataBlock(void *object, unsigned long offset, unsigned char *buffer, unsigned long length)
{
	//NSLog(@"%s %p %lu %lu %p", __FUNCTION__, object, offset, length, buffer);

	UXReaderDocument *self = (__bridge UXReaderDocument *)object; // Data source

	return [self->dataSource document:self offset:offset length:length buffer:buffer];
}

#pragma mark - UXReaderDocument instance methods

- (instancetype)init
{
	//NSLog(@"%s", __FUNCTION__);

	if ((self = [super init])) // Initialize superclass
	{
		prioritizePerformance = [UXReaderFramework prioritizePerformance];

		documentPages = [NSMapTable strongToWeakObjectsMapTable];
	}

	return self;
}

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL
{
	//NSLog(@"%s %@", __FUNCTION__, URL);

	if ((self = [self init])) // Initialize self
	{
		if (URL != nil) documentURL = [URL copy]; else self = nil;
	}

	return self;
}

- (nullable instancetype)initWithData:(nonnull NSData *)data
{
	//NSLog(@"%s %p", __FUNCTION__, data);

	if ((self = [self init])) // Initialize self
	{
		if (data != nil) documentData = [data copy]; else self = nil;
	}

	return self;
}

- (nullable instancetype)initWithSource:(nonnull id <UXReaderDocumentDataSource>)source
{
	//NSLog(@"%s %@", __FUNCTION__, source);

	if ((self = [self init])) // Initialize self
	{
		if (source != nil) dataSource = source; else self = nil;
	}

	return self;
}

- (void)dealloc
{
	//NSLog(@"%s", __FUNCTION__);

	dataSource = nil; documentPages = nil;

	if (pdfDocument != nil) // FPDF_DOCUMENT
	{
		[UXReaderFramework dispatch_sync_on_work_queue:
		^{
			FPDF_CloseDocument(self->pdfDocument); self->pdfDocument = nil;
		}];
	}
}

- (nullable NSURL *)URL
{
	//NSLog(@"%s", __FUNCTION__);

	return documentURL;
}

- (nullable NSData *)data
{
	//NSLog(@"%s", __FUNCTION__);

	return documentData;
}

- (void)setTitle:(nonnull NSString *)text
{
	//NSLog(@"%s %@", __FUNCTION__, text);

	title = [text copy];
}

- (nullable NSString *)title
{
	//NSLog(@"%s", __FUNCTION__);

	if (title == nil) // Create title
	{
		if (documentURL != nil) // NSURL file name
		{
			NSString *filename = [documentURL lastPathComponent];

			title = [filename stringByDeletingPathExtension];
		}
		else if (documentData != nil) // NSData object address
		{
			title = [NSString stringWithFormat:@"%p", documentData];
		}
		else if (dataSource != nil) // UXReaderDocumentDataSource
		{
			title = [NSString stringWithFormat:@"%p", dataSource];
		}
	}

	return title;
}

- (BOOL)hasEqualURL:(nullable NSURL *)URL
{
	//NSLog(@"%s %@", __FUNCTION__, URL);

	if (documentURL == nil) return NO; // Not equal

	BOOL result = [documentURL isEqual:URL]; // NSURL ==

	if ((result == NO) && [documentURL isFileURL] && [URL isFileURL])
	{
		id value1 = nil; id value2 = nil; // NSURLFileResourceIdentifierKey values

		[documentURL getResourceValue:&value1 forKey:NSURLFileResourceIdentifierKey error:nil];

		[URL getResourceValue:&value2 forKey:NSURLFileResourceIdentifierKey error:nil];

		result = [value1 isEqual:value2];
	}

	return result;
}

- (BOOL)isSameDocument:(nonnull UXReaderDocument *)documentx
{
	//NSLog(@"%s %@", __FUNCTION__, documentx);

	BOOL result = [self isEqual:documentx]; // NSObject ==

	if (result == NO) result = [self hasEqualURL:[documentx URL]];

	return result;
}

/*
- (BOOL)openWithPassword:(nullable NSString *)password error:(NSError * __autoreleasing __nullable * __nullable)error
{
	//NSLog(@"%s %@", __FUNCTION__, password);

	assert(pdfDocument == nil);

	if (error != nil) *error = nil;

	__block NSUInteger errorCode = FPDF_ERR_SUCCESS;

	const char *phrase = [password UTF8String];

	if ([documentURL isFileURL]) // File NSURL
	{
		[UXReaderFramework dispatch_sync_on_work_queue:
		^{
			NSString *path = [documentURL path];

			const char *filepath = [path UTF8String];

			pdfDocument = FPDF_LoadDocument(filepath, phrase);

			errorCode = FPDF_GetLastError(); [self metadata];
		}];
	}
	else if ([documentData length]) // NSData
	{
		[UXReaderFramework dispatch_sync_on_work_queue:
		^{
			const void *data = [documentData bytes];

			const int size = int([documentData length]);

			pdfDocument = FPDF_LoadMemDocument(data, size, phrase);

			errorCode = FPDF_GetLastError(); [self metadata];
		}];
	}
	else if (dataSource != nil) // UXReaderDocumentDataSource
	{
		[UXReaderFramework dispatch_sync_on_work_queue:
		^{
			FPDF_FILEACCESS data; memset(&data, 0x00, sizeof(data));

			size_t length = 0; [dataSource document:self dataLength:&length];

			data.m_FileLen = length; data.m_GetBlock = &GetDataBlock;

			data.m_Param = (__bridge void *)self; // UXReaderDocument

			pdfDocument = FPDF_LoadCustomDocument(&data, phrase);

			errorCode = FPDF_GetLastError(); [self metadata];
		}];
	}
	else if ([documentURL host]) // HTTP NSURL
	{
		[UXReaderFramework dispatch_sync_on_work_queue:
		^{
			dataSource = self; // UXReaderDocumentDataSource

			FPDF_FILEACCESS data; memset(&data, 0x00, sizeof(data));

			size_t length = 0; [dataSource document:self dataLength:&length];

			data.m_FileLen = length; data.m_GetBlock = &GetDataBlock;

			data.m_Param = (__bridge void *)self; // UXReaderDocument

			pdfDocument = FPDF_LoadCustomDocument(&data, phrase);

			errorCode = FPDF_GetLastError(); [self metadata];
		}];
	}

	if ((pdfDocument == nil) && (error != nil)) // Return NSError
	{
		NSString *name = NSStringFromClass([self class]); // UXReaderDocument

		NSString *text = [NSString stringWithFormat:@"%@ Error %lu", name, errorCode];

		NSDictionary<NSString *, id> *userInfo = @{NSLocalizedDescriptionKey : text};

		*error = [NSError errorWithDomain:name code:errorCode userInfo:userInfo];
	}

	return (pdfDocument != nil);
}
*/

- (void)openWithPassword:(nullable NSString *)password completion:(nonnull void (^)(NSError *__nullable error))handler
{
	//NSLog(@"%s %@", __FUNCTION__, password);

	assert(pdfDocument == nil); assert(handler != nil);

	[UXReaderFramework dispatch_async_on_work_queue:
	^{
		NSError *error = nil; // Open NSError

		const char *phrase = [password UTF8String];

		if ([self->documentURL isFileURL]) // File NSURL
		{
			NSString *path = [self->documentURL path];

			const char *filepath = [path UTF8String];

			self->pdfDocument = FPDF_LoadDocument(filepath, phrase);
		}
		else if ([self->documentData length]) // NSData
		{
			const void *data = [self->documentData bytes];

			const int size = int([self->documentData length]);

			self->pdfDocument = FPDF_LoadMemDocument(data, size, phrase);
		}
		else if (self->dataSource != nil) // UXReaderDocumentDataSource
		{
			FPDF_FILEACCESS data; memset(&data, 0x00, sizeof(data));

			size_t length = 0; [self->dataSource document:self dataLength:&length];

			data.m_FileLen = length; data.m_GetBlock = &GetDataBlock;

			data.m_Param = (__bridge void *)self; // UXReaderDocument

			self->pdfDocument = FPDF_LoadCustomDocument(&data, phrase);
		}
		else if ([self->documentURL host]) // HTTP NSURL
		{
			self->dataSource = self; // UXReaderDocumentDataSource

			FPDF_FILEACCESS data; memset(&data, 0x00, sizeof(data));

			size_t length = 0; [self->dataSource document:self dataLength:&length];

			data.m_FileLen = length; data.m_GetBlock = &GetDataBlock;

			data.m_Param = (__bridge void *)self; // UXReaderDocument

			self->pdfDocument = FPDF_LoadCustomDocument(&data, phrase);
		}

		if (self->pdfDocument == nil) // Return NSError
		{
			const NSUInteger errorCode = FPDF_GetLastError();

			NSString *name = NSStringFromClass([self class]); // UXReaderDocument

			NSString *text = [NSString stringWithFormat:@"%@ Error %lu", name, errorCode];

			NSDictionary<NSString *, id> *userInfo = @{NSLocalizedDescriptionKey : text};

			error = [NSError errorWithDomain:name code:errorCode userInfo:userInfo];
		}
		else // Extract document metadata
		{
			[self metadata];
		}

		dispatch_async(dispatch_get_main_queue(), ^{ handler(error); });
	}];
}

- (void)metadata
{
	//NSLog(@"%s", __FUNCTION__);

	if (pdfDocument != nil) // Get metadata
	{
		pageCount = FPDF_GetPageCount(pdfDocument);

		if (pageCount > 100) prioritizePerformance = NO;

		pageSizes = [[NSMutableDictionary alloc] initWithCapacity:pageCount];

		for (NSUInteger page = 0; page < pageCount; page++)
		{
			double width = 0.0; double height = 0.0; // Page size

			if (FPDF_GetPageSizeByIndex(pdfDocument, int(page), &width, &height) != FALSE)
			{
				pageSizes[@(page)] = [NSValue valueWithSize:NSMakeSize(floor(width), floor(height))];
			}
		}
	}
}

- (BOOL)isOpen
{
	//NSLog(@"%s", __FUNCTION__);

	return (pdfDocument != nil);
}

- (nonnull void *)pdfDocument
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	return pdfDocument;
}

- (NSUInteger)pageCount
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	return pageCount;
}

- (NSSize)pageSize:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	assert(pdfDocument != nil);

	return [pageSizes[@(page)] sizeValue];
}

- (nullable NSDictionary<NSNumber *, NSValue *> *)pageSizes
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	return pageSizes;
}

- (void)enumeratePageSizesUsingBlock:(nonnull void (^)(NSUInteger page, NSSize size))block
{
	//NSLog(@"%s %p", __FUNCTION__, block);

	assert(pdfDocument != nil);

	if (block != nil) // Valid block - carry on
	{
		for (NSUInteger page = 0; page < pageCount; page++)
		{
			block(page, [pageSizes[@(page)] sizeValue]);
		}
	}
}

- (nullable UXReaderDocumentPage *)documentPage:(NSUInteger)page
{
	//NSLog(@"%s %lu", __FUNCTION__, page);

	assert(pdfDocument != nil);

	UXReaderDocumentPage *documentPage = [documentPages objectForKey:@(page)];

	if (documentPage == nil) // Create new UXReaderDocumentPage for requested page
	{
		if ((documentPage = [[UXReaderDocumentPage alloc] initWithDocument:self page:page]))
		{
			[documentPages setObject:documentPage forKey:@(page)];
		}
	}

	return documentPage;
}

- (BOOL)prioritizePerformance
{
	//NSLog(@"%s", __FUNCTION__);

	return prioritizePerformance;
}

#pragma mark - UXReaderDocument search methods

- (BOOL)isSearching
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	return (searchCanceller != nil);
}

- (void)cancelSearch
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	if (UXReaderCanceller *canceller = searchCanceller)
	{
		[canceller cancel]; [[canceller lock] lock]; [[canceller lock] unlock];
	}
}

- (void)beginSearch:(nonnull NSString *)text options:(UXReaderSearchOptions)options
{
	//NSLog(@"%s '%@' %lu", __FUNCTION__, text, options);

	assert(pdfDocument != nil);

	if ((searchCanceller == nil) && [text length])
	{
		searchCanceller = [[UXReaderCanceller alloc] init];

		NSString *string = [text copy]; // Make copy of search text

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
		^{
			[[self->searchCanceller lock] lock]; NSUInteger total = 0;

			dispatch_async(dispatch_get_main_queue(),
			^{
				if ([self->search respondsToSelector:@selector(document:didBeginDocumentSearch:)])
				{
					[self->search document:self didBeginDocumentSearch:options];
				}
			});

			const NSRange range = NSMakeRange(0, [string length]);

			const NSUInteger bytes = ((range.length + 1) * sizeof(unichar));

			NSMutableData *unicode = [[NSMutableData alloc] initWithLength:bytes];

			[string getCharacters:reinterpret_cast<unichar *>([unicode mutableBytes]) range:range];

			for (NSUInteger page = 0; page < self->pageCount; page++)
			{
				if ([self->searchCanceller isCancelled]) break;

				dispatch_async(dispatch_get_main_queue(),
				^{
					if ([self->search respondsToSelector:@selector(document:didBeginPageSearch:pages:)])
					{
						[self->search document:self didBeginPageSearch:page pages:self->pageCount];
					}
				});

				total += [self searchPage:page unicode:unicode options:options];

				dispatch_async(dispatch_get_main_queue(),
				^{
					if ([self->search respondsToSelector:@selector(document:didFinishPageSearch:total:)])
					{
						[self->search document:self didFinishPageSearch:page total:total];
					}
				});
			}

			dispatch_async(dispatch_get_main_queue(),
			^{
				if ([self->search respondsToSelector:@selector(document:didFinishDocumentSearch:)])
				{
					[self->search document:self didFinishDocumentSearch:total];
				}
			});

			[[self->searchCanceller lock] unlock];

			self->searchCanceller = nil;
		});
	}
}

- (NSUInteger)searchPage:(NSUInteger)page unicode:(nonnull NSData *)unicode options:(UXReaderSearchOptions)options
{
	//NSLog(@"%s %lu %p %lu", __FUNCTION__, page, unicode, options);

	__block NSUInteger found = 0;

	[UXReaderFramework dispatch_sync_on_work_queue:
	^{
		if (UXReaderDocumentPage *documentPage = [self documentPage:page])
		{
			const FPDF_TEXTPAGE textPage = [documentPage textPage]; // Handle

			const unichar *term = reinterpret_cast<const unichar *>([unicode bytes]);

			if (const FPDF_SCHHANDLE handle = FPDFText_FindStart(textPage, term, options, 0))
			{
				NSMutableArray<UXReaderTextSelection *> *selections = [[NSMutableArray alloc] init];

				while (FPDFText_FindNext(handle)) // Loop over any search hits
				{
					const int index = FPDFText_GetSchResultIndex(handle);

					const int count = FPDFText_GetSchCount(handle);

					//const NSUInteger bytes = ((count + 1) * sizeof(unichar));

					//NSMutableData *data = [[NSMutableData alloc] initWithLength:bytes];

					//const int cc = FPDFText_GetText(textPage, index, count, reinterpret_cast<unichar *>([data mutableBytes]));

					//NSString *text = [[NSString alloc] initWithCharacters:reinterpret_cast<const unichar *>([data bytes]) length:(cc - 1)];

					const int rc = FPDFText_CountRects(textPage, index, count); found++;

					NSMutableArray<NSValue *> *rects = [[NSMutableArray alloc] initWithCapacity:rc];

					for (int ri = 0; ri < rc; ri++) // Get all rectangles for the search hit
					{
						double x1 = 0.0; double y1 = 0.0; double x2 = 0.0; double y2 = 0.0;

						FPDFText_GetRect(textPage, ri, &x1, &y2, &x2, &y1); // Page co-ordinates

						const double d = 1.0; x1 -= d; y1 -= d; x2 += d; y2 += d; // Outset rectangle

						const NSRect rect = [documentPage convertFromPageX1:x1 Y1:y1 X2:x2 Y2:y2];

						[rects addObject:[NSValue valueWithRect:rect]];
					}

					if (UXReaderTextSelection *selection = [UXReaderTextSelection document:self page:page index:index count:count rectangles:rects])
					{
						[selections addObject:selection];
					}
				}

				if ([selections count] > 0) // Have hits
				{
					dispatch_async(dispatch_get_main_queue(),
					^{
						if ([self->search respondsToSelector:@selector(document:searchDidMatch:page:)])
						{
							[self->search document:self searchDidMatch:selections page:page];
						}
					});
				}

				FPDFText_FindClose(handle);
			}
		}
	}];

	return found;
}

- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections
{
	//NSLog(@"%s %@", __FUNCTION__, selections);

	assert(pdfDocument != nil);

	if (selections != searchSelections) // Update
	{
		searchSelections = [selections copy]; // Keep copy

		for (NSNumber *number in documentPages) // For cached pages
		{
			if (searchSelections != nil) // Update with new search selections
			{
				NSArray<UXReaderTextSelection *> *pageSelections = searchSelections[number];

				if (UXReaderDocumentPage *documentPage = [documentPages objectForKey:number])
				{
					[documentPage setSearchSelections:pageSelections];
				}
			}
			else // Clear any search selections
			{
				if (UXReaderDocumentPage *documentPage = [documentPages objectForKey:number])
				{
					[documentPage setSearchSelections:nil];
				}
			}
		}
	}
}

- (nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)searchSelections
{
	//NSLog(@"%s", __FUNCTION__);

	assert(pdfDocument != nil);

	return searchSelections;
}

#pragma mark - UXReaderDocumentDataSource methods

- (BOOL)document:(UXReaderDocument *)document dataLength:(size_t *)length
{
	//NSLog(@"%s %@ %p", __FUNCTION__, document, length);

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:documentURL];

	[request setHTTPMethod:@"HEAD"]; request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

	__autoreleasing NSHTTPURLResponse *response = nil; __autoreleasing NSError *error = nil; BOOL status = NO;

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if ((response.statusCode == 200) && (error == nil) && ([data length] == 0))
	{
		NSDictionary<NSString *, NSString *> *headers = [response allHeaderFields];

		NSString *acceptRanges = headers[@"Accept-Ranges"]; NSString *contentLength = headers[@"Content-Length"];

		if ([acceptRanges isEqualToString:@"bytes"] && (contentLength != nil))
		{
			*length = [contentLength integerValue]; status = YES;
		}
	}

	return status;
}

- (BOOL)document:(UXReaderDocument *)document offset:(size_t)offset length:(size_t)length buffer:(uint8_t *)buffer
{
	//NSLog(@"%s %@ %lu %lu %p", __FUNCTION__, document, offset, length, buffer);

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:documentURL]; [request setHTTPMethod:@"GET"];

	const size_t last = (offset + length - 1); NSString *range = [NSString stringWithFormat:@"bytes=%lu-%lu", offset, last];

	[request setValue:range forHTTPHeaderField:@"Range"]; request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

	__autoreleasing NSHTTPURLResponse *response = nil; __autoreleasing NSError *error = nil; BOOL status = NO;

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if ((response.statusCode == 206) && (error == nil) && ([data length] == length))
	{
		memcpy(buffer, [data bytes], length); status = YES;
	}

	return status;
}

@end
