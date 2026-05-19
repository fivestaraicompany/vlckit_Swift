#import "VLCStreamOutput.h"
#import "../Playback/VLCMediaPlayer.h"
#import "../Media/VLCMedia.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCStreamSession)
@interface VLCStreamSession : VLCMediaPlayer
+ (instancetype)streamSession;
@property (nonatomic, strong) VLCStreamOutput *streamOutput;
@property (nonatomic, readonly) BOOL isComplete;
@property (nonatomic, readonly) NSUInteger reattemptedConnections;
- (void)startStreaming;
- (void)stopStreaming;
@end

NS_ASSUME_NONNULL_END
