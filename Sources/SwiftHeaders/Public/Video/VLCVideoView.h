#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCVideoView)
@interface VLCVideoView : NSView
@property (nonatomic, copy) NSColor *backColor;
@property (nonatomic, readonly) BOOL hasVideo;
@property (nonatomic) BOOL fillScreen;
@end

NS_ASSUME_NONNULL_END
