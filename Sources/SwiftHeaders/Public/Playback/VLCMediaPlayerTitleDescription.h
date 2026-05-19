#import <Foundation/Foundation.h>

@class VLCTime;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VLCMediaPlayer.ChapterDescription)
@interface VLCMediaPlayerChapterDescription : NSObject
@property (nonatomic, readonly) VLCTime *timeOffset;
@property (nonatomic, readonly) VLCTime *durationTime;
@property (nonatomic, readonly, nullable, copy) NSString *name;
@property (nonatomic, readonly) int chapterIndex;
@property (nonatomic, readonly) int titleIndex;
@property (nonatomic, readonly, nullable) NSURL *mediaURL;
@property (nonatomic, getter=isCurrent, readonly) BOOL current;

- (void)setCurrent;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef NS_OPTIONS(unsigned, VLCMediaPlayerTitleType) {
    VLCMediaPlayerTitleTypeMenu = 0x01,
    VLCMediaPlayerTitleTypeInteractive = 0x02,
};

NS_SWIFT_NAME(VLCMediaPlayer.TitleDescription)
@interface VLCMediaPlayerTitleDescription : NSObject
@property (nonatomic, readonly) VLCTime *durationTime;
@property (nonatomic, readonly, nullable, copy) NSString *name;
@property (nonatomic, readonly) VLCMediaPlayerTitleType titleType;
@property (nonatomic, readonly, copy) NSArray<VLCMediaPlayerChapterDescription *> *chapterDescriptions;
@property (nonatomic, readonly) int titleIndex;
@property (nonatomic, readonly, nullable) NSURL *mediaURL;
@property (nonatomic, readonly, getter=isMenu) BOOL menu;
@property (nonatomic, readonly, getter=isCurrent) BOOL current;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)setCurrent;
- (void)navigateActivate;
- (void)navigateUp;
- (void)navigateDown;
- (void)navigateLeft;
- (void)navigateRight;
- (void)navigatePopup;
@end

NS_ASSUME_NONNULL_END
