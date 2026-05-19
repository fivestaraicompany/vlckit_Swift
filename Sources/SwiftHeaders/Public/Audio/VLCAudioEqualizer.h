#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCAudioEqualizer.Preset)
@interface VLCAudioEqualizerPreset : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) unsigned index;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_SWIFT_NAME(VLCAudioEqualizer.Band)
@interface VLCAudioEqualizerBand : NSObject
@property (nonatomic, readonly) float frequency;
@property (nonatomic, readonly) unsigned index;
@property (nonatomic) float amplification;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_SWIFT_NAME(VLCAudioEqualizer)
@interface VLCAudioEqualizer : NSObject
@property (class, nonatomic, copy, readonly) NSArray<VLCAudioEqualizerPreset *> *presets;
@property (nonatomic) float preAmplification;
@property (nonatomic, copy, readonly) NSArray<VLCAudioEqualizerBand *> *bands;

- (instancetype)init;
- (instancetype)initWithPreset:(VLCAudioEqualizerPreset *)preset;
@end

NS_ASSUME_NONNULL_END
