#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * VLCDefaultStreamOutputRTSP;
extern NSString * VLCDefaultStreamOutputRTP;

NS_SWIFT_NAME(VLCStreamOutput)
@interface VLCStreamOutput : NSObject
- (instancetype)initWithOptionDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;
+ (instancetype)streamOutputWithOptionDictionary:(NSDictionary *)dictionary;
+ (id)rtpBroadcastStreamOutputWithSAPAnnounce:(NSString *)announceName;
+ (id)rtpBroadcastStreamOutput;
+ (id)ipodStreamOutputWithFilePath:(NSString *)filePath;
+ (instancetype)streamOutputWithFilePath:(NSString *)filePath;
+ (id)mpeg2StreamOutputWithFilePath:(NSString *)filePath;
+ (id)mpeg4StreamOutputWithFilePath:(NSString *)filePath;
@end

NS_ASSUME_NONNULL_END
