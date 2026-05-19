#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMediaPlayer;

NS_SWIFT_NAME(VLCFilterParameterProtocol)
@protocol VLCFilterParameter <NSObject>
@property (nonatomic) id value;
@property (nonatomic, readonly) id defaultValue;
@property (nonatomic, readonly) id minValue;
@property (nonatomic, readonly) id maxValue;
- (BOOL)isValueSetToDefault;
@end

NS_SWIFT_NAME(VLCFilterProtocol)
@protocol VLCFilter <NSObject>
@property (nonatomic, weak, readonly) VLCMediaPlayer *mediaPlayer;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, readonly) NSDictionary<NSString *, id<VLCFilterParameter>> *parameters;
- (BOOL)resetParametersIfNeeded;
- (void)applyParametersFrom:(id<VLCFilter>)otherFilter;
@end

NS_ASSUME_NONNULL_END
