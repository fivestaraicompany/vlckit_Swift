import Foundation

@objc public final class VLCFileLogger: NSObject, VLCFormattedMessageLogging {
    
     @objc public let fileHandle: FileHandle
     @objc public var level: VLCLogLevel = .debug
     @objc public var formatter: VLCLogMessageFormatting = VLCLogMessageFormatter()
    
     @objc public required init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
         super.init()
       }
    
    public func handleMessage(_ message: String, logLevel: VLCLogLevel, context: VLCLogContext?) {
        if logLevel.rawValue > level.rawValue { return }
        let formatted = formatter.format(with: message, logLevel: logLevel, context: context)
        if let data = formatted.data(using: .utf8) {
             if #available(iOS 13.0, tvOS 13.0, macOS 10.15, *) {
                 try? fileHandle.write(contentsOf: data)
               } else {
                  try? fileHandle.write(data)
               }
           }
       }
}
