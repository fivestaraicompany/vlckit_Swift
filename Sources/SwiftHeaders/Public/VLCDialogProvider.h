#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VLCLibrary;

typedef NS_ENUM(NSUInteger, VLCDialogQuestionType) {
    VLCDialogQuestionNormal,
    VLCDialogQuestionWarning,
    VLCDialogQuestionCritical,
};

NS_SWIFT_NAME(VLCCustomDialogRendererProtocol)
@protocol VLCCustomDialogRendererProtocol <NSObject>
- (void)showErrorWithTitle:(NSString *)error message:(NSString *)message;
- (void)showLoginWithTitle:(NSString *)title message:(NSString *)message defaultUsername:(nullable NSString *)username askingForStorage:(BOOL)askingForStorage withReference:(NSValue *)reference;
- (void)showQuestionWithTitle:(NSString *)title message:(NSString *)message type:(VLCDialogQuestionType)questionType cancelString:(nullable NSString *)cancelString action1String:(nullable NSString *)action1String action2String:(nullable NSString *)action2String withReference:(NSValue *)reference;
- (void)showProgressWithTitle:(NSString *)title message:(NSString *)message isIndeterminate:(BOOL)isIndeterminate position:(float)position cancelString:(nullable NSString *)cancelString withReference:(NSValue *)reference;
- (void)updateProgressWithReference:(NSValue *)reference message:(nullable NSString *)message position:(float)position;
- (void)cancelDialogWithReference:(NSValue *)reference;
@end

NS_SWIFT_NAME(VLCDialogProvider)
@interface VLCDialogProvider : NSObject
- (nullable instancetype)initWithLibrary:(nullable VLCLibrary *)library customUI:(BOOL)customUI;
@property (weak, readwrite, nonatomic, nullable) id<VLCCustomDialogRendererProtocol> customRenderer;
- (void)postUsername:(NSString *)username andPassword:(NSString *)password forDialogReference:(NSValue *)dialogReference store:(BOOL)store;
- (void)postAction:(int)buttonNumber forDialogReference:(NSValue *)dialogReference;
- (void)dismissDialogWithReference:(NSValue *)dialogReference;
@end

NS_ASSUME_NONNULL_END
