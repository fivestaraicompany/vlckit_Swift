#import <Foundation/Foundation.h>

@protocol VLCEventsConfiguring;

@interface VLCEventsHandler : NSObject
@property (nonatomic, readonly, weak) id _Nullable object;
+ (instancetype)handlerWithObject:(id)object configuration:(id<VLCEventsConfiguring> _Nullable)configuration;
- (instancetype)initWithObject:(id)object configuration:(id<VLCEventsConfiguring> _Nullable)configuration NS_DESIGNATED_INITIALIZER;
- (void)handleEvent:(void (^)(id))handle;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
