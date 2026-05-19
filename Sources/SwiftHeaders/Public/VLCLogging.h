#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCLogLevel)
    NS_SWIFT_NAME(VLCLogLevel);

typedef NS_OPTIONS(NSInteger, VLCLogContextFlag)
    NS_SWIFT_NAME(VLCLog.ContextFlag);

NS_SWIFT_NAME(VLCLog.Context)
@interface VLCLogContext : NSObject
@property (nonatomic, readonly) uintptr_t objectId;
@property (nonatomic, readonly, copy) NSString *objectType;
@property (nonatomic, readonly, copy) NSString *module;
@property (nonatomic, readonly, nullable, copy) NSString *header;
@property (nonatomic, readonly, nullable, copy) NSString *file;
@property (nonatomic, readonly) int line;
@property (nonatomic, readonly, nullable, copy) NSString *function;
@property (nonatomic, readonly) unsigned long threadId;
@end

@protocol VLCLogMessageFormatting <NSObject>
@property (nonatomic, readwrite) VLCLogContextFlag contextFlags;
@property (nonatomic, readwrite, nullable) id customContext;
- (NSString *)formatWithMessage:(NSString *)message logLevel:(VLCLogLevel)level context:(nullable VLCLogContext *)context;
@end

@protocol VLCLogging <NSObject>
@property (readwrite, nonatomic) VLCLogLevel level;
- (void)handleMessage:(NSString *)message logLevel:(VLCLogLevel)level context:(nullable VLCLogContext *)context;
@end

@protocol VLCFormattedMessageLogging <VLCLogging>
@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;
@end

NS_ASSUME_NONNULL_END
