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
    private var _formatter: (any VLCLogMessageFormatting)?

       /**
     Create a new console logger
         */
    public override init() {
         _formatter = VLCLogMessageFormatter()
        super.init()
         }

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

    public func handleMessage(_ message: String, debugLevel level: Int) {
        guard let formatter = _formatter else { return }

        let formattedMessage = formatter.format(withMessage: message, logLevel: VLCLogLevel(rawValue: level) ?? .debug, context: nil)
        print(formattedMessage)
       }
}
