#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCRendererItem, VLCRendererDiscoverer;

NS_SWIFT_NAME(VLCRendererDiscoverer.Delegate)
@protocol VLCRendererDiscovererDelegate <NSObject>
- (void)rendererDiscovererItemAdded:(VLCRendererDiscoverer *)rendererDiscoverer item:(VLCRendererItem *)item;
- (void)rendererDiscovererItemDeleted:(VLCRendererDiscoverer *)rendererDiscoverer item:(VLCRendererItem *)item;
@end

NS_SWIFT_NAME(VLCRendererDiscovererDescription)
@interface VLCRendererDiscovererDescription : NSObject
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *longName;
- (instancetype)initWithName:(NSString *)name longName:(NSString *)longName;
@end

NS_SWIFT_NAME(VLCRendererDiscoverer)
@interface VLCRendererDiscoverer : NSObject
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSArray<VLCRendererItem *> *renderers;
@property (nonatomic, weak, nullable) id<VLCRendererDiscovererDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithName:(NSString *)name;

- (NSArray<VLCRendererItem *> *)renderers;
- (BOOL)start;
- (void)stop;

+ (nullable NSArray<VLCRendererDiscovererDescription *> *)list;
@end

NS_ASSUME_NONNULL_END
