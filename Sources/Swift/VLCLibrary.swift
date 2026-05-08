//
//  VLCLibrary.swift
//  VLCKit
//
//  VLCLibrary - The base library of VLCKit.framework
//

import Foundation
import CLibVLC

/**
 Protocol for receiving log messages from VLCLibrary
 */
public protocol VLCLogging {
    /// The logging level (0=info, 1=error, 2=warning, 3-4=debug)
    var level: Int { get set }

    /// Handle a log message
    func handleMessage(_ message: String, debugLevel level: Int)
}

/**
 Protocol for receiving debug log messages
 */
public protocol VLCLibraryLogReceiverProtocol {
    /// Handle a log message
    func handleMessage(_ message: String, debugLevel level: Int)
}

/**
 Protocol for configuring events
 */
public protocol VLCEventsConfiguring {
    var dispatchQueue: DispatchQueue? { get }
    var isAsync: Bool { get }
}

/**
 The VLCLibrary is the base library of VLCKit.framework. This object provides a shared instance that exposes the
 internal functionalities of libvlc and libvlc-control.
 */
public final class VLCLibrary: NSObject {

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
            if let loggers = loggers, !loggers.isEmpty {
                libvlc_log_set(instance, { data, level, ctx, fmt, args in
                    VLCLibrary.logHandler(data, Int(level), ctx, fmt, args)
                }, Unmanaged.passUnretained(self).toOpaque())
            }
        }
    }

    /// Enable debug logging to console
    @available(*, deprecated, message: "Set loggers with setLoggers() instead")
    public var debugLogging: Bool {
        get {
            return (loggers?.count ?? 0) > 0
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

        // Create C string array for libvlc_new
        var cStrings = allOptions.map { strdup($0) }
        let argc = Int32(cStrings.count)

        instance = cStrings.withUnsafeMutableBufferPointer { buffer -> OpaquePointer? in
            // Convert [UnsafeMutablePointer<CChar>?] to [UnsafePointer<CChar>?]
            var constPtrs = buffer.map { UnsafePointer($0) }
            return constPtrs.withUnsafeMutableBufferPointer { constBuffer in
                return libvlc_new(argc, constBuffer.baseAddress)
            }
        }

        // Free the C strings
        for ptr in cStrings {
            free(ptr)
        }

        guard instance != nil else {
            fatalError("libvlc failed to initialize")
        }
    }

    private var defaultOptions: [String] {
        if let vlcParams = UserDefaults.standard.object(forKey: "VLCParams") as? [String] {
            return vlcParams
        }

    #if os(iOS)
        return [
            "--no-color",
            "--no-osd",
            "--no-video-title-show",
            "--no-snapshot-preview",
            "--http-reconnect",
            "--text-renderer=freetype",
            "--avi-index=3",
            "--audio-resampler=soxr",
            "--avcodec-hw=videotoolbox",
            "--videotoolbox-temporal-deinterlacing"
        ]
    #else
        return [
            "--play-and-pause",
            "--no-color",
            "--no-video-title-show",
            "--verbose=4",
            "--no-sout-keep",
            "--vout=caopengllayer",
            "--text-renderer=freetype",
            "--freetype-background-opacity=0",
            "--freetype-outline-thickness=2",
            "--freetype-shadow-opacity=128",
            "--freetype-shadow-color=0",
            "--extraintf=macosx_dialog_provider",
            "--audio-resampler=soxr",
            "--avcodec-hw=videotoolbox",
            "--videotoolbox-temporal-deinterlacing"
        ]
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

    private static func logHandler(_ data: UnsafeMutableRawPointer?, _ level: Int, _ ctx: OpaquePointer?, _ fmt: UnsafePointer<CChar>?, _ args: CVaListPointer?) {
        guard let data = data else { return }
        let library = Unmanaged<VLCLibrary>.fromOpaque(data).takeUnretainedValue()

        guard let fmt = fmt else { return }

        // Format the message using vsnprintf
        var buffer = [CChar](repeating: 0, count: 512)
        if let args = args {
            vsnprintf(&buffer, buffer.count, fmt, args)
        }
        let message = String(cString: buffer)

        let logLevel = VLCLogLevel(rawValue: level) ?? .debug

        DispatchQueue.global(qos: .userInitiated).async {
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
private final class VLCExternalLogger: NSObject, VLCLogging {
    private var _target: (any VLCLibraryLogReceiverProtocol)?

    public var level: Int = 0

    public init(target: any VLCLibraryLogReceiverProtocol) {
        self._target = target
        super.init()
    }

    public func handleMessage(_ message: String, debugLevel level: Int) {
        _target?.handleMessage(message, debugLevel: level)
    }
}

// MARK: - Log Context
public final class VLCLogContext: NSObject {
    public var module: String?
    public var objectType: String?
    public var header: String?
    public var file: String?
    public var line: Int = 0
    public var function: String?

    public override init() {
        super.init()
    }
}
