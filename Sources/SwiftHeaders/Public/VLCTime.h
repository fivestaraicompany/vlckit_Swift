#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VLCTimeComparison)
    NS_SWIFT_NAME(VLCTime.Comparison);

NS_SWIFT_NAME(VLCTime)
@interface VLCTime : NSObject <NSCopying, NSSecureCoding>

+ (VLCTime *)nullTime NS_SWIFT_NAME(null());
+ (VLCTime *)timeWithNumber:(nullable NSNumber *)aNumber NS_SWIFT_NAME(from(_:));
+ (VLCTime *)timeWithInt:(int)aInt NS_SWIFT_NAME(from(_:));
+ (int64_t)clock NS_SWIFT_NAME(clock());
+ (int64_t)delay:(int64_t)ts NS_SWIFT_NAME(delay(_:));

- (nullable instancetype)initWithNumber:(nullable NSNumber *)aNumber;
- (instancetype)initWithInt:(int)aInt;

@property (nonatomic, readonly, nullable) NSNumber *value;
@property (nonatomic, readonly) NSString *stringValue;
@property (nonatomic, readonly) NSString *verboseStringValue;
@property (nonatomic, readonly) NSString *minuteStringValue;
@property (nonatomic, readonly) NSString *subSecondStringValue;
@property (nonatomic, readonly) int intValue;

- (VLCTimeComparison)compare:(VLCTime *)aTime;

@end

NS_ASSUME_NONNULL_END
