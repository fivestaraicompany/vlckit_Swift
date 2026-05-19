import Foundation

@objc public final class VLCConsoleLogger: NSObject, VLCFormattedMessageLogging {
    
     @objc public var level: VLCLogLevel = .debug
     @objc public var formatter: VLCLogMessageFormatting = VLCLogMessageFormatter()
    
    public func handleMessage(_ message: String, logLevel: VLCLogLevel, context: VLCLogContext?) {
        if logLevel.rawValue > level.rawValue { return }
        let formatted = formatter.format(with: message, logLevel: logLevel, context: context)
        VKLog(formatted.trimmingCharacters(in: .whitespacesAndNewlines))
       }
}
