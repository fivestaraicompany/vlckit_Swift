import Foundation

@objc public enum VLCLogLevel: Int {
    case error = 0
    case warning
    case info
    case debug
}

@objc public enum VLCLogContextFlag: Int {
    case none = 0
    case module = 1 << 0
    case fileLocation = 1 << 1
    case callingFunction = 1 << 2
    case custom = 1 << 3
    case all = 0xF
}

@objc public final class VLCLogContext: NSObject {
     @objc public let objectId: UInt
     @objc public let objectType: String
     @objc public let module: String
     @objc public let header: String?
     @objc public let file: String?
     @objc public let line: Int
     @objc public let function: String?
     @objc public let threadId: UInt64
    
     @objc public init(objectId: UInt, objectType: String, module: String,
                       header: String? = nil, file: String? = nil, line: Int,
                       function: String? = nil, threadId: UInt64) {
        self.objectId = objectId
        self.objectType = objectType
        self.module = module
        self.header = header
        self.file = file
        self.line = line
        self.function = function
        self.threadId = threadId
       }
}

@objc public protocol VLCLogMessageFormatting: AnyObject {
    var contextFlags: VLCLogContextFlag { get set }
    var customContext: AnyObject? { get set }
    func format(with message: String, logLevel: VLCLogLevel, context: VLCLogContext?) -> String
}

@objc public protocol VLCLogging: AnyObject {
    var level: VLCLogLevel { get set }
    func handleMessage(_ message: String, logLevel: VLCLogLevel, context: VLCLogContext?)
}

@objc public protocol VLCFormattedMessageLogging: VLCLogging {
    var formatter: VLCLogMessageFormatting { get set }
}
