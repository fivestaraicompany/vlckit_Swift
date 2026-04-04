//
//  VLCLogMessageFormatter.swift
//  VLCKit
//
//  VLCLogMessageFormatter - Log message formatter
//

import Foundation

/**
 VLCLogMessageFormatter - Log message formatter for VLC
 */
public class VLCLogMessageFormatter: NSObject {

    private var _contextFlags: UInt = 0
    private var _customContext: NSObject?

    private let kVLCLogLevelContextNone: UInt = 0
    private let kVLCLogLevelContextModule: UInt = 1
    private let kVLCLogLevelContextFileLocation: UInt = 2
    private let kVLCLogLevelContextCallingFunction: UInt = 4
    private let kVLCLogLevelContextCustom: UInt = 8

        /**
     Create a new log message formatter

          - Returns: A new log message formatter instance
          */
    public override init() {
        super.init()
         }

    public var contextFlags: UInt {
        get { return _contextFlags }
        set { _contextFlags = newValue }
         }

    public var customContext: NSObject? {
        get { return _customContext }
        set {
            _customContext = newValue
            if newValue != nil {
                _contextFlags |= kVLCLogLevelContextCustom
             }
           }
         }

    private func prefix(from level: VLCLogLevel) -> String {
        switch level {
        case .notice:
            return "INF"
        case .error:
            return "ERR"
        case .warning:
            return "WARN"
        case .debug:
            return "DBG"
        @unknown default:
            return "DBG"
          }
         }

    public func contextDescription(for context: VLCLogContext?) -> String {
        guard _contextFlags != kVLCLogLevelContextNone else {
            return ""
         }

        var messageContext = ""

        if _contextFlags & kVLCLogLevelContextModule != 0 {
            messageContext.append(" [\($0.module ?? "")/\($0.objectType ?? "")]")
         }

        if _contextFlags & kVLCLogLevelContextFileLocation != 0 {
            messageContext.append(" [\($0.file ?? ""):\($0.line)]")
         }

        if _contextFlags & kVLCLogLevelContextCallingFunction != 0 {
            messageContext.append(" [from \($0.function ?? "")]")
         }

        if _contextFlags & kVLCLogLevelContextCustom != 0, let customContext = _customContext {
            messageContext.append(" [\($0.description)]")
         }

        return messageContext
          }

    public func format(withMessage message: String, logLevel level: VLCLogLevel, context: VLCLogContext?) -> String {
        return "[\(prefix(from: level))] \(message)\(contextDescription(for: context))"
         }
}
