#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerVolumeChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.volumeChangedNotification);

NS_SWIFT_NAME(VLCAudio)
@interface VLCAudio : NSObject
@property (getter=isMuted) BOOL muted;
@property (assign) int volume;
@property (readwrite) BOOL passthrough;

- (void)volumeDown;
- (void)volumeUp;
@end

NS_ASSUME_NONNULL_END
