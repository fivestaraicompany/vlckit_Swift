#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCTranscoder;

NS_SWIFT_NAME(VLCTranscoder.Delegate)
@protocol VLCTranscoderDelegate <NSObject>
@optional
- (void)transcode:(VLCTranscoder *)transcoder finishedSucessfully:(BOOL)success;
@end

NS_SWIFT_NAME(VLCTranscoder)
@interface VLCTranscoder : NSObject
@property (weak, nonatomic, nullable) id<VLCTranscoderDelegate> delegate;
- (BOOL)reencodeAndMuxSRTFile:(NSString *)srtPath toMP4File:(NSString *)mp4Path outputPath:(NSString *)outPath;
@end

NS_ASSUME_NONNULL_END
