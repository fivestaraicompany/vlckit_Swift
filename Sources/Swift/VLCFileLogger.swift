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

        /**
     Create a new file logger

        - Parameter fileHandle: The file handle to write to
        - Returns: A new file logger instance
        */
    public convenience init(fileHandle: FileHandle) {
        self.init()
         _fileHandle = fileHandle
         _formatter = VLCLogMessageFormatter()
         }

    public var level: Int = 0

    public var formatter: (any VLCLogMessageFormatting)? {
        get { return _formatter }
        set {
            guard let newValue = newValue else {
                print("Set a nil formatter isn't allowed, keeping previous formatter")
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
        let messageData = formattedMessage.data(using: .utf8) ?? Data()

        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, *) {
            try? _fileHandle.write(contentsOf: messageData)
             } else {
            do {
                try _fileHandle.write(contentsOf: messageData)
                } catch {
                    /// Silently fails
                 }
             }
         }
}
