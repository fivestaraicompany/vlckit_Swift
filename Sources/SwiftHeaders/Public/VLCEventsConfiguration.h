#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VLCEventsConfiguring <NSObject>
- (dispatch_queue_t _Nullable)dispatchQueue;
- (BOOL)isAsync;
@end

NS_SWIFT_NAME(VLCEvents.DefaultConfiguration)
@interface VLCEventsDefaultConfiguration : NSObject <VLCEventsConfiguring>
@end

NS_SWIFT_NAME(VLCEvents.LegacyConfiguration)
@interface VLCEventsLegacyConfiguration : NSObject <VLCEventsConfiguring>
@end

NS_ASSUME_NONNULL_END
