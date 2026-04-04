//
//  VLCKitSwiftWrapper.h
//  MobileVLCKit
//
//  Swift-friendly wrapper for VLCKit C API
//

#import <Foundation/Foundation.h>
#import <MobileVLCKit/MobileVLCKit.h>

NS_ASSUME_NONNULL_BEGIN

/// VLCKit Swift Wrapper - C API 를 Swift 에서 쉽게 사용할 수 있도록 래퍼
@interface VLCKitWrapper : NSObject

/// 싱글톤 인스턴스
+ (instancetype)sharedInstance;

/// libvlc 인스턴스
@property (nonatomic, strong, readonly) VLCMediaPlayer *mediaPlayer;

/// 초기화
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedInstance NS_SWIFT_NAME(shared());

@end

/// MediaPlayer Wrapper
@interface VLCMediaPlayerWrapper : NSObject

@property (nonatomic, strong, readonly) VLCMediaPlayer *player;
@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, assign, readonly) BOOL isPaused;
@property (nonatomic, assign, readonly) BOOL isSeekable;

- (instancetype)initWithPlayer:(VLCMediaPlayer *)player NS_DESIGNATED_INITIALIZER;
+ (instancetype)playerWithPlayer:(VLCMediaPlayer *)player;

/// 재생
- (void)play;

/// 일시정지
- (void)pause;

/// 중지
- (void)stop;

/// 시크
- (void)seekToTime:(NSTimeInterval)time;

/// 볼륨 조절
- (void)setVolume:(NSInteger)volume;

/// 재생 상태
- (NSString *)playingState;

@end

/// Media Wrapper
@interface VLCMediaWrapper : NSObject

@property (nonatomic, strong, readonly) VLCMedia *media;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, assign, readonly) NSTimeInterval length;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithPath:(NSString *)path;

/// 메타데이터
- (NSDictionary *)metadata;
- (NSString *)mime;

@end

/// Media List Wrapper
@interface VLCMediaListWrapper : NSObject

@property (nonatomic, strong, readonly) VLCMediaList *mediaList;

- (instancetype)initWithMediaList:(VLCMediaList *)mediaList;

/// 항목 추가
- (void)addMedia:(VLCMedia *)media;
- (void)addMediaWithURL:(NSURL *)url;

/// 항목 제거
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;

/// 항목 개수
- (NSInteger)count;

@end

/// Media List Player Wrapper
@interface VLCMediaListPlayerWrapper : NSObject

@property (nonatomic, strong, readonly) VLCMediaListPlayer *listPlayer;
@property (nonatomic, strong, readonly) VLCMediaPlayer *player;

- (instancetype)initWithListPlayer:(VLCMediaListPlayer *)listPlayer;

/// 재생
- (void)play;

/// 중지
- (void)stop;

/// 다음으로
- (void)next;

/// 이전으로
- (void)previous;

@end

NS_ASSUME_NONNULL_END
