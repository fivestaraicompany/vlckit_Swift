#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCVideoLayer)
@interface VLCVideoLayer : CALayer
@property (nonatomic, readonly) BOOL hasVideo;
@property (nonatomic) BOOL fillScreen;
@end

NS_ASSUME_NONNULL_END
