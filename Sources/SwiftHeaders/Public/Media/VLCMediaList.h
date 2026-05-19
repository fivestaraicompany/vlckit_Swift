#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const VLCMediaListItemAddedNotification NS_SWIFT_NAME(VLCMediaList.itemAddedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaListItemDeletedNotification NS_SWIFT_NAME(VLCMediaList.itemDeletedNotification);

@class VLCMedia;

NS_SWIFT_NAME(VLCMediaList.Delegate)
@protocol VLCMediaListDelegate <NSObject>
@optional
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSUInteger)index;
- (void)mediaList:(VLCMediaList *)aMediaList mediaRemovedAtIndex:(NSUInteger)index;
@end

NS_SWIFT_NAME(VLCMediaList)
@interface VLCMediaList : NSObject
- (instancetype)initWithArray:(nullable NSArray<VLCMedia *> *)array;

- (void)lock;
- (void)unlock;
- (NSUInteger)addMedia:(VLCMedia *)media;
- (void)insertMedia:(VLCMedia *)media atIndex:(NSUInteger)index;
- (BOOL)removeMediaAtIndex:(NSUInteger)index;
- (nullable VLCMedia *)mediaAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfMedia:(VLCMedia *)media;

@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, weak, nullable) id<VLCMediaListDelegate> delegate;
@property (nonatomic, readonly) BOOL isReadOnly;
@property (nonatomic, readonly) BOOL isEmpty;
@end

NS_ASSUME_NONNULL_END
