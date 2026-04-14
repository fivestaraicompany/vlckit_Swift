//
//  VLCFileLogger.swift
//  VLCKit
//
//  VLCFileLogger - File logger for VLC
//

import Foundation

/**
 VLCFileLogger - File logger for VLC
 */
public class VLCFileLogger: NSObject, VLCLogging {

    private let _fileHandle: FileHandle
    private var _formatter: (any VLCLogMessageFormatting)?

    public var level: Int = 0

    public init(fileHandle: FileHandle) {
        _fileHandle = fileHandle
        _formatter = VLCLogMessageFormatter()
        super.init()
    }

    public var formatter: (any VLCLogMessageFormatting)? {
        get { return _formatter }
        set {
            guard let newValue = newValue else {
                print("Setting a nil formatter isn't allowed, keeping previous formatter")
                return
            }
            _formatter = newValue
        }
    }

    public static func create(withFileHandle fileHandle: FileHandle) -> VLCFileLogger {
        return VLCFileLogger(fileHandle: fileHandle)
    }

    public func handleMessage(_ message: String, debugLevel level: Int) {
        guard level >= self.level, let formatter = _formatter else { return }

        let formattedMessage = formatter.format(withMessage: message, logLevel: VLCLogLevel(rawValue: level) ?? .debug, context: nil)
        if let data = formattedMessage.data(using: .utf8) {
            if #available(iOS 13.4, tvOS 13.4, macOS 10.15.4, *) {
                try? _fileHandle.write(contentsOf: data)
            } else {
                _fileHandle.write(data)
            }
        }
    }
}
