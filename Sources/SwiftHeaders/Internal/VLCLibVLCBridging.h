#import "VLCLibrary.h"
#import "VLCMediaPlayer.h"
#import "VLCMediaList.h"
#import "VLCMedia.h"
#import "VLCAudio.h"
#import "VLCMediaMetaData.h"
#import "VLCAudioEqualizer.h"
#import "VLCMediaPlayerTitleDescription.h"
#import "VLCTime.h"

#if !TARGET_OS_IPHONE
#import "VLCStreamOutput.h"
#endif

#if !TARGET_OS_TV
#import "VLCRendererItem.h"
#endif

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class VLCMediaList, VLCMedia, VLCMediaPlayer, VLCAudio, VLCAudioEqualizer, VLCMediaMetaData, VLCTime;
@protocol VLCEventsConfiguring;

@interface VLCLibrary (VLCLibVLCBridging)
+ (void *)sharedInstance;
@property (readonly) void *instance;
@end

@interface VLCLibrary (VLCAudioBridging)
- (void)setAudio:(VLCAudio *)value;
@end

@interface VLCMedia (LibVLCBridging)
+ (nullable instancetype)mediaWithLibVLCMediaDescriptor:(void *)md;
- (nullable instancetype)initWithLibVLCMediaDescriptor:(void *)md;
+ (nullable instancetype)mediaWithMedia:(VLCMedia *)media andLibVLCOptions:(NSDictionary *)options;
@property (readonly) void *libVLCMediaDescriptor;
- (void)setLength:(VLCTime *)value;
@end

@interface VLCMediaPlayer (LibVLCBridging)
@property (readonly) void *libVLCMediaPlayer;
@end

@interface VLCMediaList (LibVLCBridging)
+ (id)mediaListWithLibVLCMediaList:(void *)p_new_mlist;
- (id)initWithLibVLCMediaList:(void *)p_new_mlist;
@property (readonly) void *libVLCMediaList;
@end

@interface VLCAudio (VLCAudioBridging)
- (instancetype)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer;
@end

@interface VLCMediaTrack (LibVLCBridging)
- (nullable instancetype)initWithMediaTrack:(void *)track;
@end

@interface VLCMediaAudioTrack (LibVLCBridging)
- (nullable instancetype)initWithAudioTrack:(void *)audio;
@end

@interface VLCMediaVideoTrack (LibVLCBridging)
- (nullable instancetype)initWithVideoTrack:(void *)video;
@end

@interface VLCMediaTextTrack (LibVLCBridging)
- (nullable instancetype)initWithSubtitleTrack:(void *)subtitle;
@end

@interface VLCMediaMetaData (LibVLCBridging)
- (instancetype)initWithMedia:(VLCMedia *)media;
- (void)handleMediaMetaChanged:(void)type;
@end

@interface VLCMediaPlayerTrack (LibVLCBridging)
- (nullable instancetype)initWithMediaTrack:(void *)track mediaPlayer:(VLCMediaPlayer *)mediaPlayer;
@end

@interface VLCMediaPlayerChapterDescription (LibVLCBridging)
- (instancetype)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer titleIndex:(int)titleIndex chapterDescription:(void *)chapter_description chapterIndex:(int)chapterIndex;
@end

@interface VLCMediaPlayerTitleDescription (LibVLCBridging)
- (instancetype)initWithMediaPlayer:(VLCMediaPlayer *)mediaPlayer titleDescription:(void *)title_description titleIndex:(int)titleIndex;
- (void)navigate:(void)navigate_mode;
@end

#if !TARGET_OS_TV
@interface VLCRendererItem (VLCRendererItemBridging)
- (instancetype)initWithRendererItem:(void *)item;
- (void *)libVLCRendererItem;
@end
#endif

#if !TARGET_OS_IPHONE
@interface VLCStreamOutput (LibVLCBridge)
- (NSString *)representedLibVLCOptions;
@end
#endif

NS_ASSUME_NONNULL_END
