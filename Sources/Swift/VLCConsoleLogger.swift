//
//  VLCConsoleLogger.swift
//  VLCKit
//
//  VLCConsoleLogger - Console logger for VLC
//

import Foundation

/**
 VLCConsoleLogger - Console logger for VLC
 */
public class VLCConsoleLogger: NSObject, VLCLogging {

    public var level: Int = 0
    private var _formatter: any VLCLogMessageFormatting

    public override init() {
        _formatter = VLCLogMessageFormatter()
        super.init()
    }

    public var formatter: any VLCLogMessageFormatting {
        get { return _formatter }
        set { _formatter = newValue }
    }

    public func handleMessage(_ message: String, debugLevel level: Int) {
        let formattedMessage = _formatter.format(withMessage: message, logLevel: VLCLogLevel(rawValue: level) ?? .debug, context: nil)
        print(formattedMessage)
    }
}
