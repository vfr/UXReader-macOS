//
//	UXReaderDocument.h
//	UXReader Framework v0.1
//
//	Created by Julius Oklamcak on 2017-01-01.
//	Copyright © 2017-2019 Julius Oklamcak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UXReaderDocument;
@class UXReaderDocumentPage;
@class UXReaderTextSelection;

typedef NS_ENUM(NSUInteger, UXReaderSearchOptions)
{
	UXReaderCaseSensitiveSearchOption = 1,
	UXReaderCaseInsensitiveSearchOption = 0,
	UXReaderMatchWholeWordSearchOption = 2
};

@protocol UXReaderDocumentSearchDelegate <NSObject>

@optional // Delegate protocols

- (void)document:(nonnull UXReaderDocument *)document didBeginDocumentSearch:(NSUInteger)kind;
- (void)document:(nonnull UXReaderDocument *)document didFinishDocumentSearch:(NSUInteger)total;
- (void)document:(nonnull UXReaderDocument *)document didBeginPageSearch:(NSUInteger)page pages:(NSUInteger)pages;
- (void)document:(nonnull UXReaderDocument *)document didFinishPageSearch:(NSUInteger)page total:(NSUInteger)total;

@required // Delegate protocols

- (void)document:(nonnull UXReaderDocument *)document searchDidMatch:(nonnull NSArray<UXReaderTextSelection *> *)selections page:(NSUInteger)page;

@end

@protocol UXReaderDocumentDataSource <NSObject>

@required // Data source protocols

- (BOOL)document:(nonnull UXReaderDocument *)document dataLength:(nonnull size_t *)length;
- (BOOL)document:(nonnull UXReaderDocument *)document offset:(size_t)offset length:(size_t)length buffer:(nonnull uint8_t *)buffer;

@end

@interface UXReaderDocument : NSObject <NSObject>

@property (nullable, weak, nonatomic, readwrite) id <UXReaderDocumentSearchDelegate> search;

- (nullable instancetype)initWithURL:(nonnull NSURL *)URL;
- (nullable instancetype)initWithData:(nonnull NSData *)data;
- (nullable instancetype)initWithSource:(nonnull id <UXReaderDocumentDataSource>)source;

- (nullable NSURL *)URL;
- (nullable NSData *)data;

- (void)setTitle:(nonnull NSString *)text;
- (nullable NSString *)title;

- (BOOL)isSameDocument:(nonnull UXReaderDocument *)document;

- (void)openWithPassword:(nullable NSString *)password completion:(nonnull void (^)(NSError *__nullable error))handler;
- (BOOL)isOpen;

- (nonnull void *)pdfDocument;

- (NSUInteger)pageCount;

- (NSSize)pageSize:(NSUInteger)page;
- (nullable NSDictionary<NSNumber *, NSValue *> *)pageSizes;
- (void)enumeratePageSizesUsingBlock:(nonnull void (^)(NSUInteger page, NSSize size))block;

- (nullable UXReaderDocumentPage *)documentPage:(NSUInteger)page;

- (BOOL)isSearching;
- (void)cancelSearch;
- (void)beginSearch:(nonnull NSString *)text options:(UXReaderSearchOptions)options;

- (void)setSearchSelections:(nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)selections;
- (nullable NSDictionary<NSNumber *, NSArray<UXReaderTextSelection *> *> *)searchSelections;

- (BOOL)prioritizePerformance;

@end

typedef NS_ENUM(NSUInteger, UXReaderDocumentError)
{
	UXReaderDocumentErrorSuccess = 0,
	UXReaderDocumentErrorUnknown = 1,
	UXReaderDocumentErrorFile = 2,
	UXReaderDocumentErrorFormat = 3,
	UXReaderDocumentErrorPassword = 4,
	UXReaderDocumentErrorSecurity = 5,
	UXReaderDocumentErrorPage = 6
};
