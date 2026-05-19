#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double VLCKitVersionNumber;
FOUNDATION_EXPORT const unsigned char VLCKitVersionString[];

// VLCKit Framework umbrella header for Swift imports

// Core
#import "VLCLibrary.h"
#import "VLCTime.h"

// Events
#import "VLCEventsConfiguration.h"
#import "VLCEventsHandler.h"

// Logging
#import "VLCLogging.h"
#import "VLCConsoleLogger.h"
#import "VLCFileLogger.h"
#import "VLCLogMessageFormatter.h"

// Media
#import "VLCMedia.h"
#import "VLCMediaList.h"
#import "VLCMediaMetaData.h"

// Playback
#import "VLCMediaPlayer.h"
#import "VLCMediaListPlayer.h"
#import "VLCMediaPlayerTitleDescription.h"

// Audio
#import "VLCAudio.h"
#import "VLCAudioEqualizer.h"

// Filters
#import "VLCFilter.h"
#import "VLCAdjustFilter.h"

// Renderer
#import "VLCRendererDiscoverer.h"
#import "VLCRendererItem.h"

// Tools
#import "VLCMediaDiscoverer.h"
#import "VLCMediaThumbnailer.h"

// Dialogs
#import "VLCDialogProvider.h"

// Video
#import "VLCVideoCommon.h"
#import "VLCDrawable.h"
#import "VLCVideoLayer.h"
#import "VLCVideoView.h"

// Sout
#import "VLCStreamOutput.h"
#import "VLCStreamSession.h"
#import "VLCTranscoder.h"
