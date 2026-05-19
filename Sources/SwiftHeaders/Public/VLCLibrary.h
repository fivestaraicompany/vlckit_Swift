#import <Foundation/Foundation.h>

@protocol VLCEventsConfiguring;
@protocol VLCLogging;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCLibrary)
@interface VLCLibrary : NSObject

@property (class, nonatomic, nullable) id<VLCEventsConfiguring> sharedEventsConfiguration;
@property (class, nonatomic, copy, nullable) NSString *currentErrorMessage NS_SWIFT_NAME(currentErrorMessage);

+ (VLCLibrary *)sharedLibrary NS_SWIFT_NAME(shared());

- (instancetype)initWithOptions:(NSArray<NSString *> *)options;

@property (readwrite, nonatomic, nullable) NSArray<id<VLCLogging>> *loggers;

@property (nonatomic, readonly, copy) NSString *version;
@property (nonatomic, readonly, copy) NSString *compiler;
@property (nonatomic, readonly, copy) NSString *changeset;

- (void)setHumanReadableName:(NSString *)readableName withHTTPUserAgent:(NSString *)userAgent;
- (void)setApplicationIdentifier:(NSString *)identifier withVersion:(NSString *)version andApplicationIconName:(NSString *)icon;

@property (nonatomic, assign) void *instance;

@end

NS_ASSUME_NONNULL_END
