#import "VLCLogging.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCLog.ConsoleLogger)
@interface VLCConsoleLogger : NSObject <VLCFormattedMessageLogging>
@property (nonatomic, readwrite) id<VLCLogMessageFormatting> formatter;
@end

NS_ASSUME_NONNULL_END
