#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, VLCRendererPlay) {
    VLCRendererPlaysAudio = 1 << 0,
    VLCRendererPlaysVideo = 1 << 1,
};

NS_SWIFT_NAME(VLCRendererItem)
@interface VLCRendererItem : NSObject
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly, copy) NSString *iconURI;
@property (nonatomic, readonly, assign) int flags;

- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
