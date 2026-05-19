#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCPictureInPictureMediaControlling)
@protocol VLCPictureInPictureMediaControlling <NSObject>
- (void)play;
- (void)pause;
- (void)seekBy:(int64_t)offset completion:(dispatch_block_t)completion;
- (int64_t)mediaLength;
- (int64_t)mediaTime;
- (BOOL)isMediaSeekable;
- (BOOL)isMediaPlaying;
@end

NS_SWIFT_NAME(VLCPictureInPictureWindowControlling)
@protocol VLCPictureInPictureWindowControlling <NSObject>
@property (nonatomic) void(^stateChangeEventHandler)(BOOL isStarted);
- (void)startPictureInPicture;
- (void)stopPictureInPicture;
- (void)invalidatePlaybackState;
@end

NS_SWIFT_NAME(VLCDrawable)
@protocol VLCDrawable <NSObject>
- (void)addSubview:(id)view;
- (CGRect)bounds;
@end

NS_SWIFT_NAME(VLCPictureInPictureDrawable)
@protocol VLCPictureInPictureDrawable <NSObject>
- (id<VLCPictureInPictureMediaControlling>)mediaController;
- (void (^)(id<VLCPictureInPictureWindowControlling>))pictureInPictureReady;
@end

NS_ASSUME_NONNULL_END
