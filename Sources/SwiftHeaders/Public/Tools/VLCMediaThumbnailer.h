#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCMedia, VLCLibrary;

NS_SWIFT_NAME(VLCMediaThumbnailer.Delegate)
@protocol VLCMediaThumbnailerDelegate <NSObject>
@required
- (void)mediaThumbnailerDidTimeOut:(VLCMediaThumbnailer *)mediaThumbnailer;
- (void)mediaThumbnailer:(VLCMediaThumbnailer *)mediaThumbnailer didFinishThumbnail:(CGImageRef)thumbnail;
@end

NS_SWIFT_NAME(VLCMediaThumbnailer)
@interface VLCMediaThumbnailer : NSObject
+ (VLCMediaThumbnailer *)thumbnailerWithMedia:(VLCMedia *)media andDelegate:(id<VLCMediaThumbnailerDelegate>)delegate;
+ (VLCMediaThumbnailer *)thumbnailerWithMedia:(VLCMedia *)media delegate:(id<VLCMediaThumbnailerDelegate>)delegate andVLCLibrary:(nullable VLCLibrary *)library;

- (void)fetchThumbnail;

@property (readwrite, weak, nonatomic, nullable) id<VLCMediaThumbnailerDelegate> delegate;
@property (readwrite, nonatomic) VLCMedia *media;
@property (readwrite, assign, nonatomic, nullable) CGImageRef thumbnail;
@property (readwrite, assign, nonatomic) CGFloat thumbnailHeight;
@property (readwrite, assign, nonatomic) CGFloat thumbnailWidth;
@property (readwrite, assign, nonatomic) float snapshotPosition;
@end

NS_ASSUME_NONNULL_END
