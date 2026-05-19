#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCLibrary, VLCMediaList;

typedef NS_ENUM(unsigned, VLCMediaDiscovererCategoryType) {
    VLCMediaDiscovererCategoryTypeDevices = 0,
    VLCMediaDiscovererCategoryTypeLAN,
    VLCMediaDiscovererCategoryTypePodcasts,
    VLCMediaDiscovererCategoryTypeLocalDirectories,
};

extern NSString * const VLCMediaDiscovererName;
extern NSString * const VLCMediaDiscovererLongName;
extern NSString * const VLCMediaDiscovererCategory;

NS_SWIFT_NAME(VLCMediaDiscoverer)
@interface VLCMediaDiscoverer : NSObject
@property (nonatomic, readonly) VLCLibrary *libraryInstance;

+ (NSArray<NSDictionary *> *)availableMediaDiscovererForCategoryType:(VLCMediaDiscovererCategoryType)categoryType;

- (instancetype)initWithName:(NSString *)aServiceName;
- (instancetype)initWithName:(NSString *)aServiceName libraryInstance:(nullable VLCLibrary *)libraryInstance;

- (int)startDiscoverer;
- (void)stopDiscoverer;

@property (nonatomic, weak, readonly, nullable) VLCMediaList *discoveredMedia;
@property (nonatomic, readonly) BOOL isRunning;
@end

NS_ASSUME_NONNULL_END
