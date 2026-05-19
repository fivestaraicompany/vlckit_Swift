#import "VLCLogging.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCLog.FileLogger)
@interface VLCFileLogger : NSObject <VLCFormattedMessageLogging>
@property (nonatomic, readonly) NSFileHandle *fileHandle;
@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle NS_DESIGNATED_INITIALIZER;
+ (instancetype)createWithFileHandle:(NSFileHandle *)fileHandle NS_SWIFT_NAME(init(fileHandle:));
@end

NS_ASSUME_NONNULL_END
