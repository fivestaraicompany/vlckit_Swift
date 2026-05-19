#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMedia, VLCMediaPlayer, VLCMediaList;

typedef NS_ENUM(NSInteger, VLCRepeatMode) {
    VLCDoNotRepeat = 0,
    VLCRepeatCurrentItem = 1,
    VLCRepeatAllItems = 2,
};

NS_SWIFT_NAME(VLCMediaListPlayer.Delegate)
@protocol VLCMediaListPlayerDelegate <NSObject>
@optional
- (void)mediaListPlayerFinishedPlayback:(VLCMediaListPlayer *)player;
- (void)mediaListPlayer:(VLCMediaListPlayer *)player nextMedia:(VLCMedia *)media;
- (void)mediaListPlayerStopped:(VLCMediaListPlayer *)player;
@end

NS_SWIFT_NAME(VLCMediaListPlayer)
@interface VLCMediaListPlayer : NSObject
@property (readwrite, nullable) VLCMediaList *mediaList;
@property (readwrite, nullable) VLCMedia *rootMedia;
@property (nonatomic, readonly) VLCMediaPlayer *mediaPlayer;
@property (nonatomic, weak, nullable) id<VLCMediaListPlayerDelegate> delegate;

- (instancetype)initWithDrawable:(id)drawable;
- (instancetype)initWithOptions:(NSArray<NSString *> *)options;
- (instancetype)initWithOptions:(nullable NSArray<NSString *> *)options andDrawable:(nullable id)drawable;

- (void)play;
- (void)pause;
- (void)stop;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL next;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL previous;

- (void)playItemAtNumber:(NSNumber *)index;

@property (readwrite) VLCRepeatMode repeatMode;
- (void)playMedia:(VLCMedia *)media;
@end

NS_ASSUME_NONNULL_END
