#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCVideoLayoutManager)
@interface VLCVideoLayoutManager : NSObject
+ (id)layoutManager;
@property (nonatomic) BOOL fillScreenEntirely;
@property (nonatomic) CGSize originalVideoSize;
@end

NS_ASSUME_NONNULL_END
