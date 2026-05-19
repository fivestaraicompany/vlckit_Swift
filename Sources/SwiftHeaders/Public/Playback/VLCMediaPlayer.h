#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class VLCLibrary, VLCMedia, VLCTime, VLCAudio, VLCMediaPlayerTrack, VLCAdjustFilter, VLCAudioEqualizer, VLCMediaPlayerTitleDescription, VLCMediaPlayerChapterDescription, VLCRendererItem;

FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerTimeChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.timeChangedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerStateChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.stateChangedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerTitleSelectionChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.titleSelectionChangedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerTitleListChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.titleListChangedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerChapterChangedNotification NS_SWIFT_NAME(VLCMediaPlayer.chapterChangedNotification);
FOUNDATION_EXPORT NSNotificationName const VLCMediaPlayerSnapshotTakenNotification NS_SWIFT_NAME(VLCMediaPlayer.snapshotTakenNotification);

typedef NS_ENUM(NSInteger, VLCMediaPlayerState) {
    VLCMediaPlayerStateStopped = 0,
    VLCMediaPlayerStateStopping = 1,
    VLCMediaPlayerStateOpening = 2,
    VLCMediaPlayerStateBuffering = 3,
    VLCMediaPlayerStateError = 4,
    VLCMediaPlayerStatePlaying = 5,
    VLCMediaPlayerStatePaused = 6,
};

typedef NS_ENUM(unsigned, VLCMediaPlaybackNavigationAction) {
    VLCMediaPlaybackNavigationActionActivate = 0,
    VLCMediaPlaybackNavigationActionUp,
    VLCMediaPlaybackNavigationActionDown,
    VLCMediaPlaybackNavigationActionLeft,
    VLCMediaPlaybackNavigationActionRight,
};

typedef NS_ENUM(NSInteger, VLCDeinterlace) {
    VLCDeinterlaceAuto = -1,
    VLCDeinterlaceOn = 1,
    VLCDeinterlaceOff = 0,
};

NSString * VLC_EXPORT VLCMediaPlayerStateToString(VLCMediaPlayerState state) NS_SWIFT_NAME(VLCMediaPlayer.stateToString(_:));

typedef NS_ENUM(NSInteger, VLCAudioStereoMode) {
    VLCAudioStereoModeUnset = 0,
    VLCAudioStereoModeStereo = 1,
    VLCAudioStereoModeRStereo = 2,
    VLCAudioStereoModeLeft = 3,
    VLCAudioStereoModeRight = 4,
    VLCAudioStereoModeDolbys = 5,
    VLCAudioStereoModeMono = 6,
};

typedef NS_ENUM(NSInteger, VLCAudioMixMode) {
    VLCAudioMixModeUnset = 0,
    VLCAudioMixModeStereo = 1,
    VLCAudioMixModeBinaural = 2,
    VLCAudioMixMode4_0 = 3,
    VLCAudioMixMode5_1 = 4,
    VLCAudioMixMode7_1 = 5,
};

NS_SWIFT_NAME(VLCMediaPlayer.Delegate)
@protocol VLCMediaPlayerDelegate <NSObject>
@optional
- (void)mediaPlayerStateChanged:(VLCMediaPlayerState)newState;
- (void)mediaPlayerTrackAdded:(NSString *)trackId type:(NSString *)trackType;
- (void)mediaPlayerTrackRemoved:(NSString *)trackId type:(NSString *)trackType;
@end

NS_SWIFT_NAME(VLCMediaPlayer)
@interface VLCMediaPlayer : NSObject

@property (nonatomic, weak, nullable) id<VLCMediaPlayerDelegate> delegate;
@property (nonatomic, readonly, nullable) VLCLibrary *library;
@property (nonatomic, readonly) VLCAudio *audio;

@property (nonatomic) VLCAudioStereoMode stereoMode;
@property (nonatomic) VLCAudioMixMode mixMode;

@property (nonatomic, readonly) VLCDeinterlace deinterlace;
@property (nonatomic) BOOL enableDeinterlace;

@property (nonatomic, readonly, copy) NSArray<NSString *> *audioDevices;
- (nullable NSString *)audioDevice;
- (void)setAudioDevice:(nullable NSString *)device;
- (nullable NSString *)audioDeviceDescription;

@property (nonatomic, readonly, copy) NSArray<NSString *> *audioDevicePairs;
- (nullable NSString *)audioDevicePair;
- (void)setAudioDevicePair:(nullable NSString *)device;

@property (nonatomic) VLCMediaPlaybackNavigationAction navigationAction;

@property (nonatomic, readonly, nullable) VLCAdjustFilter *adjustFilter;

@property (nonatomic, readonly, nullable) VLCAudioEqualizer *equalizer;
- (void)setEqualizer:(nullable VLCAudioEqualizer *)equalizer NS_SWIFT_NAME(set(equalizer:));

@property (nonatomic, readonly, nullable) VLCMedia *media;
- (void)setMedia:(nullable VLCMedia *)media NS_SWIFT_NAME(set(media:));

- (nullable VLCMedia *)addMediaWithOptions:(nullable VLCMedia *)media andLibVLCOptions:(nullable NSDictionary<NSString *, NSString *> *)options;

@property (nonatomic, readonly, nullable) NSString *tracklistIdentifier;
@property (nonatomic, readonly, copy) NSString *tracklistSubIdentifier;
@property (nonatomic, readonly, copy) NSString *tracklistIdentifierType;

@property (nonatomic) double position;
@property (nonatomic) VLCTime *time;

- (void)play NS_SWIFT_NAME(play());
- (void)pause;
- (void)stop;

- (void)playNext;
- (void)playPrevious;

- (void)shortJumpForward;
- (void)shortJumpBackward;
- (void)longJumpForward;
- (void)longJumpBackward;

- (void)performNavigationAction:(VLCMediaPlaybackNavigationAction)action;

- (BOOL)updateViewpoint:(float)yaw pitch:(float)pitch roll:(float)roll fov:(float)fov absolute:(BOOL)absolute;

@property (nonatomic) float yaw;
@property (nonatomic) float pitch;
@property (nonatomic) float roll;
@property (nonatomic) float fov;

@property (NS_NONATOMIC_IOSONLY, getter=isPlaying, readonly) BOOL playing;
@property (NS_NONATOMIC_IOSONLY, readonly) VLCMediaPlayerState state;
@property (NS_NONATOMIC_IOSONLY) BOOL position NS_SWIFT_ISSYNTAXONLY(position);
@property (NS_NONATOMIC_IOSONLY, getter=isSeekable, readonly) BOOL seekable;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL canPause;

@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSArray *snapshots;

#if TARGET_OS_IPHONE
@property (NS_NONATOMIC_IOSONLY, readonly, nullable) UIImage *lastSnapshot;
#else
@property (NS_NONATOMIC_IOSONLY, readonly, nullable) NSImage *lastSnapshot;
#endif

- (void)startRecordingAtPath:(NSString *)path;
- (void)stopRecording;

#if !TARGET_OS_TV
- (BOOL)setRendererItem:(nullable VLCRendererItem *)item;
#endif

@end

#pragma mark - Tracks

NS_SWIFT_NAME(VLCMediaPlayer.Tracks)
@interface VLCMediaPlayer (Tracks)
@property (nonatomic, readonly, copy) NSArray<VLCMediaPlayerTrack *> *audioTracks;
@property (nonatomic, readonly, copy) NSArray<VLCMediaPlayerTrack *> *videoTracks;
@property (nonatomic, readonly, copy) NSArray<VLCMediaPlayerTrack *> *textTracks;
- (void)selectTrackAtIndex:(NSInteger)index type:(VLCMedia.TrackType)type;
- (void)deselectAllAudioTracks;
- (void)deselectAllVideoTracks;
- (void)selectTextTracks:(NSArray<VLCMediaPlayerTrack *> *)tracks;
- (void)deselectAllTextTracks;
@end

NS_ASSUME_NONNULL_END
