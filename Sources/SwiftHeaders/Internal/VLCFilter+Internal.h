#import "VLCFilter.h"

typedef void(^VLCFilterParameterValueChangeAction)(id);

extern NSString * const kVLCFilterParameterPropertyLibVLCFilterOptionKey;
extern NSString * const kVLCFilterParameterPropertyParameterKey;
extern NSString * const kVLCFilterParameterPropertyDefaultValueKey;
extern NSString * const kVLCFilterParameterPropertyMinValueKey;
extern NSString * const kVLCFilterParameterPropertyMaxValueKey;
extern NSString * const kVLCFilterParameterPropertyValueChangeActionKey;

@interface VLCFilterParameter : NSObject <VLCFilterParameter>
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)createWithProperties:(NSDictionary<NSString *,id> *)properties;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProperties:(NSDictionary<NSString *,id> *)properties NS_DESIGNATED_INITIALIZER;
@end
