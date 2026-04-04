//
//  VLCLibrary.swift
//  VLCKit
//
//  VLCLibrary - The base library of VLCKit.framework
//

import Foundation

/**
 Protocol for receiving log messages from VLCLibrary
 */
public protocol VLCLogging {
    /// The logging level (0=info, 1=error, 2=warning, 3-4=debug)
    var level: Int { get set }
}

/**
 Protocol for receiving debug log messages
 */
public protocol VLCLibraryLogReceiverProtocol {
    /// Handle a log message
    /// - Parameters:
    ///    - message: The log message
    ///    - level: The log level
    func handleMessage(_ message: String, debugLevel level: Int)
}

/**
 Protocol for configuring events
 */
public protocol VLCEventsConfiguring {
    /// Handle an event
    /// - Parameter block: The event handler block
    func handleEvent(_ block: @escaping (NSObject) -> Void)
}

/**
 The VLCLibrary is the base library of VLCKit.framework. This object provides a shared instance that exposes the
 internal functionalities of libvlc and libvlc-control.
 */
public class VLCLibrary: NSObject {

    /// The shared library instance
    public static let sharedLibrary = VLCLibrary()

    /// Shared events configuration
    public static var sharedEventsConfiguration: (any VLCEventsConfiguring)? = nil

    /// The libvlc instance
    public private(set) var instance: OpaquePointer?

    /// The loggers
    public var loggers: [any VLCLogging]? = nil {
        didSet {
            guard let instance = instance else { return }

            libvlc_log_unset(instance)
            DispatchQueue.global(qos: .userInitiated).sync {
                self.loggers?.enumerated().forEach { (idx, logger) in
                    if logger.level >= 0 {
                        libvlc_log_set(instance, VLCLibrary.logHandler, UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()))
                    }
                }
            }
        }
    }

    /// Enable debug logging to console
    @available(*, deprecated, message: "Set loggers with setLoggers() instead")
    public var debugLogging: Bool {
        get {
            return loggers?.count ?? 0 > 0
        }
        set {
            self.loggers = newValue ? [VLCConsoleLogger()] : nil
        }
    }

    /// Get/set the logging level
    @available(*, deprecated, message: "Use setLogger() with a VLCConsoleLogger instance instead")
    public var debugLoggingLevel: Int {
        get {
            guard let logger = loggers?.first else { return -1 }
            return logger.level
        }
        set {
            guard var logger = loggers?.first else { return }
            logger.level = max(0, min(newValue, 3))
            loggers?[0] = logger
        }
    }

    /// The library version
    public var version: String {
        return String(cString: libvlc_get_version())
    }

    /// The compiler used to build libvlc
    public var compiler: String {
        return String(cString: libvlc_get_compiler())
    }

    /// The library's changeset
    public var changeset: String {
        return String(cString: libvlc_get_changeset())
    }

    /// Current error message
    public static var currentErrorMessage: String? {
        let errmsg = libvlc_errmsg()
        return errmsg != nil ? String(cString: errmsg!) : nil
    }

    /// Initialize with options
    public init(options: [String]? = nil) {
        super.init()
        prepareInstance(with: options)
    }

    private func prepareInstance(with options: [String]?) {
        let allOptions = options ?? defaultOptions

        let cStrings = allOptions.map { $0.cString(using: .ascii) ?? "" }
        let unsafeStrings = cStrings.map { UnsafePointer($0) }

        instance = libvlc_new(unsafeStrings.count, unsafeStrings)

        guard let instance = instance else {
            fatalError("libvlc failed to initialize")
        }
    }

    private var defaultOptions: [String] {
        if let vlcParams = UserDefaults.standard.object(forKey: "VLCParams") as? [String] {
            return vlcParams
        }

    #if TARGET_OS_IPHONE
        return [
            "--no-color",
            "--no-osd",
            "--no-video-title-show",
            "--no-snapshot-preview",
            "--http-reconnect",
            "--text-renderer=freetype",
            "--avi-index=3",
            "--audio-resampler=soxr"
        ]
    #else
        let defaultParams: [String] = [
            "--play-and-pause",
            "--no-color",
            "--no-video-title-show",
            "--verbose=4",
            "--no-sout-keep",
            "--vout=macosx",
            "--text-renderer=freetype",
            "--extraintf=macosx_dialog_provider",
            "--audio-resampler=soxr"
        ]

        UserDefaults.standard.set(defaultParams, forKey: "VLCParams")
        UserDefaults.standard.synchronize()

        return defaultParams
    #endif
    }

    /// Set human-readable name and HTTP User Agent
    public func setHumanReadableName(_ readableName: String, withHTTPUserAgent userAgent: String) {
        guard let instance = instance else { return }
        libvlc_set_user_agent(instance, readableName, userAgent)
    }

    /// Set application identifier
    public func setApplicationIdentifier(_ identifier: String, withVersion version: String, andApplicationIconName icon: String) {
        guard let instance = instance else { return }
        libvlc_set_app_id(instance, identifier, version, icon)
    }

    /// Set loggers
    public func setLoggers(_ loggers: [any VLCLogging]?) {
        self.loggers = loggers
    }

    /// Set debug logging target
    public func setDebugLoggingTarget(_ target: (any VLCLibraryLogReceiverProtocol)?) {
        guard let target = target else {
            self.loggers = nil
            return
        }
        self.loggers = [VLCExternalLogger(target: target)]
    }

    /// Set debug logging to a file
    @available(*, deprecated, message: "Use setLogger() with a VLCFileLogger instance instead")
    public func setDebugLogging(toFilePath filePath: String) -> Bool {
        let fileManager = FileManager.default

        guard fileManager.createFile(atPath: filePath, contents: nil, attributes: nil) else {
            return false
        }

        guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
            return false
        }

        fileHandle.seekToEndOfFile()

        let logger = VLCFileLogger(fileHandle: fileHandle)
        self.loggers = [logger]
        return true
    }

    private static func logHandler(_ data: UnsafeMutableRawPointer?, _ level: Int, _ ctx: UnsafePointer<libvlc_log_t>?, _ fmt: UnsafePointer<CChar>?, _ args: OpaquePointer?) {
        let library = Unmanaged<VLCLibrary>.fromOpaque(data!).takeUnretainedValue()

        var messageStr: UnsafeMutablePointer<CChar>?
        let len = vasprintf(&messageStr, fmt, args)

        guard len >= 0, let messageStr = messageStr else {
            return
        }

        let message = String(cString: messageStr)
        messageStr.deallocate()

        let logLevel: VLCLogLevel = VLCLogLevel(rawValue: level) ?? .debug

        let context: VLCLogContext = VLCLogContext(log: ctx)

        DispatchQueue.global(qos: .userInitiated).sync {
            library.loggers?.forEach { logger in
                if logLevel.rawValue >= logger.level {
                    logger.handleMessage(message, debugLevel: logLevel.rawValue)
                }
            }
        }
    }
}

// MARK: - Log Levels
public enum VLCLogLevel: Int {
    case notice = 0
    case error = 1
    case warning = 2
    case debug = 3
}

// MARK: - External Logger
private class VLCExternalLogger: NSObject, VLCLogging {
    private var _target: (any VLCLibraryLogReceiverProtocol)?
    private var _level: Int = 0

    public var target: (any VLCLibraryLogReceiverProtocol)? {
        get { return _target }
        set { _target = newValue }
    }

    public var level: Int {
        get { return _level }
        set { _level = newValue }
    }

    public init(target: (any VLCLibraryLogReceiverProtocol)) {
        self._target = target
        self._level = 0
        super.init()
    }

    public func handleMessage(_ message: String, debugLevel level: Int) {
        target?.handleMessage(message, debugLevel: level)
    }
}

// MARK: - Log Context
public class VLCLogContext: NSObject {
    public var objectId: UInt = 0
    public var objectType: String?
    public var module: String?
    public var header: String?
    public var file: String?
    public var line: Int = 0
    public var function: String?
    public var threadId: UInt = 0

    public convenience init(log ctx: UnsafePointer<libvlc_log_t>?) {
        self.init()
        guard let ctx = ctx else { return }

        self.objectId = ctx.pointee.i_object_id
        self.objectType = ctx.pointee.psz_object_type != nil ? String(cString: ctx.pointee.psz_object_type!) : nil
        self.module = ctx.pointee.psz_module != nil ? String(cString: ctx.pointee.psz_module!) : nil
        self.header = ctx.pointee.psz_header != nil ? String(cString: ctx.pointee.psz_header!) : nil
        self.file = ctx.pointee.file != nil ? String(cString: ctx.pointee.file!) : nil
        self.line = ctx.pointee.line
        self.function = ctx.pointee.func != nil ? String(cString: ctx.pointee.func!) : nil
        self.threadId = ctx.pointee.tid
    }
}
