#import "VLCFilter.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kVLCAdjustFilterContrastParameterKey;
extern NSString * const kVLCAdjustFilterBrightnessParameterKey;
extern NSString * const kVLCAdjustFilterHueParameterKey;
extern NSString * const kVLCAdjustFilterSaturationParameterKey;
extern NSString * const kVLCAdjustFilterGammaParameterKey;

NS_SWIFT_NAME(VLCAdjustFilter)
@interface VLCAdjustFilter : NSObject <VLCFilter>
@property (nonatomic, readonly) id<VLCFilterParameter> contrast;
@property (nonatomic, readonly) id<VLCFilterParameter> brightness;
@property (nonatomic, readonly) id<VLCFilterParameter> hue;
@property (nonatomic, readonly) id<VLCFilterParameter> saturation;
@property (nonatomic, readonly) id<VLCFilterParameter> gamma;

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)createWithVLCMediaPlayer:(VLCMediaPlayer *)mediaPlayer NS_SWIFT_NAME(init(mediaPlayer:));
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVLCMediaPlayer:(VLCMediaPlayer *)mediaPlayer NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
