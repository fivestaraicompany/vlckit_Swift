#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef
#if TARGET_OS_IPHONE
UIImage
#else
NSImage
#endif
VLCPlatformImage;

NS_SWIFT_NAME(VLCMedia.MetaData)
@interface VLCMediaMetaData : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *artist;
@property (nonatomic, copy, nullable) NSString *genre;
@property (nonatomic, copy, nullable) NSString *copyright;
@property (nonatomic, copy, nullable) NSString *album;
@property (nonatomic) unsigned trackNumber;
@property (nonatomic, copy, nullable) NSString *metaDescription;
@property (nonatomic, copy, nullable) NSString *rating;
@property (nonatomic, copy, nullable) NSString *date;
@property (nonatomic, copy, nullable) NSString *setting;
@property (nonatomic, nullable) NSURL *url;
@property (nonatomic, copy, nullable) NSString *language;
@property (nonatomic, copy, nullable) NSString *nowPlaying;
@property (nonatomic, copy, nullable) NSString *publisher;
@property (nonatomic, copy, nullable) NSString *encodedBy;
@property (nonatomic, nullable) NSURL *artworkURL;
@property (nonatomic) unsigned trackID;
@property (nonatomic) unsigned trackTotal;
@property (nonatomic, copy, nullable) NSString *director;
@property (nonatomic) unsigned season;
@property (nonatomic) unsigned episode;
@property (nonatomic, copy, nullable) NSString *showName;
@property (nonatomic, copy, nullable) NSString *actors;
@property (nonatomic, copy, nullable) NSString *albumArtist;
@property (nonatomic) unsigned discNumber;
@property (nonatomic) unsigned discTotal;
@property (nonatomic, readonly, nullable) VLCPlatformImage *artwork;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSString *> *extra;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)save;
- (void)prefetch;
- (void)clearCache;
- (nullable NSString *)extraValueForKey:(NSString *)key;
- (void)setExtraValue:(nullable NSString *)value forKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
