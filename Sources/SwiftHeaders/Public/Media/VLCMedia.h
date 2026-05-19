#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCTime, VLCMediaTrack, VLCMediaMetaData, VLCMediaList;

FOUNDATION_EXPORT NSNotificationName const VLCMediaMetaChangedNotification NS_SWIFT_NAME(VLCMedia.metaChangedNotification);

typedef NS_ENUM(NSInteger, VLCMedia.TrackType) {
    VLCMediaTrackTypeUnknown = -1,
    VLCMediaTrackTypeAudio = 0,
    VLCMediaTrackTypeVideo = 1,
    VLCMediaTrackTypeText = 2,
};

typedef NS_OPTIONS(unsigned, VLCMediaParseOptions) {
    VLCMediaParseNone = 0,
    VLCMediaParseLocal = 1 << 0,
    VLCMediaParseNetwork = 1 << 1,
    VLCMediaParseLocalAndNetwork = VLCMediaParseLocal | VLCMediaParseNetwork,
    VLCMediaFetchLocal = 1 << 2,
    VLCMediaFetchNetwork = 1 << 3,
    VLCMediaFetchLocalAndNetwork = VLCMediaFetchLocal | VLCMediaFetchNetwork,
    VLCMediaParseDepthMax = 16,
};

typedef NS_ENUM(NSInteger, VLCMedia.ParsedStatus) {
    VLCMediaParsedStatusSkipped = 0,
    VLCMediaParsedStatusFailed = 1,
    VLCMediaParsedStatusDone = 2,
    VLCMediaParsedStatusInProgress = 3,
};

typedef NS_ENUM(unsigned, VLCMediaPlaybackNavigationAction) {
    VLCMediaPlaybackNavigationActionActivate = 0,
    VLCMediaPlaybackNavigationActionUp,
    VLCMediaPlaybackNavigationActionDown,
    VLCMediaPlaybackNavigationActionLeft,
    VLCMediaPlaybackNavigationActionRight,
};

typedef NS_OPTIONS(unsigned, VLCMediaTitleType) {
    VLCMediaTitleTypeMenu = 0x01,
    VLCMediaTitleTypeInteractive = 0x02,
};

@protocol VLCMediaDelegate <NSObject>
@optional
- (void)mediaMetaDataDidChange:(VLCMedia *)aMedia;
- (void)mediaDidFinishParsing:(VLCMedia *)aMedia;
@end

NS_SWIFT_NAME(VLCMedia)
@interface VLCMedia : NSObject
+ (nullable instancetype)mediaWithURL:(NSURL *)anURL NS_SWIFT_NAME(init(url:));
+ (nullable instancetype)mediaWithPath:(NSString *)aPath NS_SWIFT_NAME(init(path:));
+ (nullable instancetype)mediaAsNodeWithName:(NSString *)aName NS_SWIFT_NAME(asNode(named:));

- (nullable instancetype)initWithURL:(NSURL *)anURL;
- (instancetype)initWithPath:(NSString *)aPath;

@property (nonatomic, weak, nullable) id<VLCMediaDelegate> delegate;

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) VLCMediaList *subitems;
@property (nonatomic, readonly, getter=isMRL) BOOL mrl;
@property (nonatomic, readonly) VLCMediaParsedStatus parsedStatus;
@property (nonatomic, readonly) VLCTime *length;
@property (nonatomic, readonly) VLCTime *remainingTime;
@property (nonatomic, readonly) VLCMediaMetaData *metaData;
@property (nonatomic, readonly, nullable) VLCMediaTrack *errorTrack;
@property (nonatomic, readonly) NSString *errorDescription;
@property (nonatomic, readonly) VLCMediaStats *statistics;

- (void)parse;
- (void)parseWithOptions:(VLCMediaParseOptions)parseOptions;
- (nullable VLCMedia *)addSubitem:(VLCMedia *)media;

+ (NSString *)codecNameForFourCC:(uint32_t)fourcc trackType:(VLCMedia.TrackType)trackType;

- (BOOL)saveMeta:(VLCMediaMetaData *)metaData;
@end

#pragma mark - VLCMedia.Track

NS_SWIFT_NAME(VLCMedia.Track)
@interface VLCMediaTrack : NSObject
@property (nonatomic, readonly) VLCMedia.TrackType type;
@property (nonatomic, readonly) uint32_t codec;
@property (nonatomic, readonly) uint32_t fourcc;
@property (nonatomic, readonly) int identifier;
@property (nonatomic, readonly) int profile;
@property (nonatomic, readonly) int level;
@property (nonatomic, readonly) unsigned int bitrate;
@property (nonatomic, readonly, nullable, copy) NSString *language;
@property (nonatomic, readonly, nullable, copy) NSString *trackDescription;
@property (nonatomic, readonly, nullable) VLCMediaAudioTrack *audio;
@property (nonatomic, readonly, nullable) VLCMediaVideoTrack *video;
@property (nonatomic, readonly, nullable) VLCMediaTextTrack *text;

- (NSString *)codecName;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_SWIFT_NAME(VLCMedia.AudioTrack)
@interface VLCMediaAudioTrack : NSObject
@property (nonatomic, readonly) unsigned channelsNumber;
@property (nonatomic, readonly) unsigned rate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef NS_ENUM(unsigned, VLCMediaOrientation) {
    VLCMediaOrientationTopLeft = 1,
    VLCMediaOrientationTopRight = 2,
    VLCMediaOrientationBottomRight = 3,
    VLCMediaOrientationBottomLeft = 4,
    VLCMediaOrientationLeftTop = 5,
    VLCMediaOrientationLeftBottom = 6,
    VLCMediaOrientationRightTop = 7,
    VLCMediaOrientationRightBottom = 8,
};

typedef NS_ENUM(unsigned, VLCMediaProjection) {
    VLCMediaProjectionGeneric = 0,
    VLCMediaProjectionEquirectangular,
    VLCMediaProjectionCubemap,
    VLCMediaProjectionCubemapLayoutStandard,
};

NS_SWIFT_NAME(VLCMedia.VideoTrack)
@interface VLCMediaVideoTrack : NSObject
@property (nonatomic, readonly) unsigned height;
@property (nonatomic, readonly) unsigned width;
@property (nonatomic, readonly) VLCMediaOrientation orientation;
@property (nonatomic, readonly) VLCMediaProjection projection;
@property (nonatomic, readonly) unsigned sourceAspectRatio;
@property (nonatomic, readonly) unsigned sourceAspectRatioDenominator;
@property (nonatomic, readonly) unsigned frameRate;
@property (nonatomic, readonly) unsigned frameRateDenominator;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_SWIFT_NAME(VLCMedia.TextTrack)
@interface VLCMediaTextTrack : NSObject
@property (nonatomic, readonly, nullable, copy) NSString *encoding;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_SWIFT_NAME(VLCMedia.Stats)
@interface VLCMediaStats : NSObject
@property (nonatomic, readonly) int opened;
@property (nonatomic, readonly) int readBytes;
@property (nonatomic, readonly) double inputBitrate;
@property (nonatomic, readonly) int demuxReadBytes;
@property (nonatomic, readonly) double demuxBitrate;
@property (nonatomic, readonly) int demuxCorrupted;
@property (nonatomic, readonly) int demuxDecoded;
@property (nonatomic, readonly) int audioDecoded;
@property (nonatomic, readonly) int audioBuffers;
@property (nonatomic, readonly) int audioLost;
@property (nonatomic, readonly) int audioOutputSamples;
@property (nonatomic, readonly) int audioOutputLost;
@property (nonatomic, readonly) int videoDecoded;
@property (nonatomic, readonly) int videoBuffers;
@property (nonatomic, readonly) int videoDisplayed;
@property (nonatomic, readonly) int videoLate;
@property (nonatomic, readonly) int videoLost;
@property (nonatomic, readonly) int audioPlayed;
@property (nonatomic, readonly) int audioBuffersLost;
@end

#pragma mark - VLCMediaPlayer.Track

NS_SWIFT_NAME(VLCMediaPlayer.Track)
@interface VLCMediaPlayerTrack : VLCMediaTrack
@property (nonatomic, readonly, copy) NSString *trackId;
@property (nonatomic, readonly, getter=isIdStable) BOOL idStable;
@property (nonatomic, readonly, copy) NSString *trackName;
@property (nonatomic, readonly, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isSelectedExclusively) BOOL selectedExclusively NS_SWIFT_NAME(selectedExclusively);
- (void)setSelectedExclusively:(BOOL)selectedExclusively NS_SWIFT_NAME(setSelectedExclusively(_:));
- (void)setSelected:(BOOL)selected NS_SWIFT_NAME(setSelected(_:));
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
