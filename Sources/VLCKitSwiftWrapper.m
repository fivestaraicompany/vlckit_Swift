//
//  VLCKitSwiftWrapper.m
//  MobileVLCKit
//
//  Swift-friendly wrapper implementation for VLCKit C API
//

#import "VLCKitSwiftWrapper.h"
#import <AVFoundation/AVFoundation.h>

@implementation VLCKitWrapper

+ (instancetype)sharedInstance {
    static VLCKitWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VLCKitWrapper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mediaPlayer = [[VLCMediaPlayer alloc] init];
    }
    return self;
}

@end

@implementation VLCMediaPlayerWrapper

- (instancetype)initWithPlayer:(VLCMediaPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
    }
    return self;
}

+ (instancetype)playerWithPlayer:(VLCMediaPlayer *)player {
    return [[self alloc] initWithPlayer:player];
}

- (BOOL)isPlaying {
    return [self.player playState] == VLCPlaying;
}

- (BOOL)isPaused {
    return [self.player playState] == VLCPaused;
}

- (BOOL)isSeekable {
    return [self.player isSeekable];
}

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)stop {
    [self.player stop];
}

- (void)seekToTime:(NSTimeInterval)time {
    [self.player seek:time];
}

- (void)setVolume:(NSInteger)volume {
    [self.player setVolume:volume];
}

- (NSString *)playingState {
    switch ([self.player playState]) {
        case VLCPlaying:
            return @"Playing";
        case VLCPaused:
            return @"Paused";
        case VLCStopped:
            return @"Stopped";
        case VLCOpening:
            return @"Opening";
        case VLCError:
            return @"Error";
        default:
            return @"Unknown";
    }
}

@end

@implementation VLCMediaWrapper

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _media = [VLCMedia mediaWithURL:url];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _media = [VLCMedia mediaWithPath:path];
    }
    return self;
}

- (NSDictionary *)metadata {
    return @{
        @"title": self.title,
        @"url": self.url.absoluteString,
        @"length": @(self.length),
        @"mime": [self mime]
    };
}

- (NSString *)mime {
    return self.media.mime;
}

- (NSString *)title {
    return self.media.title;
}

- (NSURL *)url {
    return self.media.url;
}

- (NSTimeInterval)length {
    return self.media.length;
}

@end

@implementation VLCMediaListWrapper

- (instancetype)initWithMediaList:(VLCMediaList *)mediaList {
    self = [super init];
    if (self) {
        _mediaList = mediaList;
    }
    return self;
}

- (void)addMedia:(VLCMedia *)media {
    [self.mediaList addMedia:media];
}

- (void)addMediaWithURL:(NSURL *)url {
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    [self.mediaList addMedia:media];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.mediaList removeItemAtIndexPath:indexPath];
}

- (NSInteger)count {
    return self.mediaList.count;
}

@end

@implementation VLCMediaListPlayerWrapper

- (instancetype)initWithListPlayer:(VLCMediaListPlayer *)listPlayer {
    self = [super init];
    if (self) {
        _listPlayer = listPlayer;
        _player = listPlayer.player;
    }
    return self;
}

- (void)play {
    [self.listPlayer play];
}

- (void)stop {
    [self.listPlayer stop];
}

- (void)next {
    [self.listPlayer next];
}

- (void)previous {
    [self.listPlayer previous];
}

@end
