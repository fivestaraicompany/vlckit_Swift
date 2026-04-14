//
//  VLCMedia.swift
//  VLCKit
//
//  VLCMedia - Media object for VLC playback
//

import Foundation
import CLibVLC

/**
 Delegate for VLCMedia events
 */
public protocol VLCMediaDelegate: AnyObject {
    /// Called when media metadata changes
    func mediaMetaDataDidChange(_ media: VLCMedia)
    /// Called when media parsing is complete
    func mediaDidFinishParsing(_ media: VLCMedia)
}

/**
 Media state enumeration
 */
public enum VLCMediaState: Int {
    case nothingSpecial = 0
    case buffering
    case playing
    case error
}

/**
 Media type enumeration
 */
public enum VLCMediaType: Int {
    case unknown = 0
    case file
    case directory
    case disc
    case stream
    case playlist
}

/**
 Media projection enumeration
 */
public enum VLCMediaProjection: Int {
    case rectangular = 0
    case equiRectangular
    case cubemapLayoutStandard = 0x100
}

/**
 Media orientation enumeration
 */
public enum VLCMediaOrientation: Int {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case leftTop
    case leftBottom
    case rightTop
    case rightBottom
}

/**
 Media parsing options
 */
public struct VLCMediaParsingOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let local = VLCMediaParsingOptions(rawValue: 0x00)
    public static let network = VLCMediaParsingOptions(rawValue: 0x01)
    public static let fetchLocal = VLCMediaParsingOptions(rawValue: 0x02)
    public static let fetchNetwork = VLCMediaParsingOptions(rawValue: 0x04)
    public static let interact = VLCMediaParsingOptions(rawValue: 0x08)
}

/**
 Media parsing status
 */
public enum VLCMediaParsedStatus: Int {
    case initial = 0
    case skipped
    case failed
    case timeout
    case done
}

/**
 Media statistics structure
 */
public struct VLCMediaStats {
    public var readBytes: Int32 = 0
    public var inputBitrate: Float = 0
    public var demuxReadBytes: Int32 = 0
    public var demuxBitrate: Float = 0
    public var demuxCorrupted: Int32 = 0
    public var demuxDiscontinuity: Int32 = 0
    public var decodedVideo: Int32 = 0
    public var decodedAudio: Int32 = 0
    public var displayedPictures: Int32 = 0
    public var lostPictures: Int32 = 0
    public var playedAudioBuffers: Int32 = 0
    public var lostAudioBuffers: Int32 = 0
    public var sentPackets: Int32 = 0
    public var sentBytes: Int32 = 0
    public var sendBitrate: Float = 0
}

// Track info keys
public let VLCMediaTracksInformationType = "type"
public let VLCMediaTracksInformationTypeVideo = "video"
public let VLCMediaTracksInformationTypeAudio = "audio"
public let VLCMediaTracksInformationTypeText = "text"
public let VLCMediaTracksInformationVideoHeight = "height"
public let VLCMediaTracksInformationVideoWidth = "width"

/**
 VLCMedia - Defines files and streams as a managed object
 */
public class VLCMedia: NSObject {

    /// Media delegate
    public weak var delegate: (any VLCMediaDelegate)?

    /// Media length
    public var length: VLCTime?

    /// Media URL
    public private(set) var url: URL?

    /// Media state
    public private(set) var state: VLCMediaState = .nothingSpecial

    /// Media type
    public private(set) var mediaType: VLCMediaType = .unknown

    /// Subitems
    public private(set) var subitems: VLCMediaList?

    /// Metadata
    public private(set) var metaData: VLCMediaMetaData!

    /// Internal libvlc media descriptor
    var libVLCMediaDescriptor: OpaquePointer? {
        return _media
    }

    private var _media: OpaquePointer?
    private var _stream: InputStream?
    private var _metaDictionary: [String: Any]?
    private var _isArtFetched: Bool = false
    private var _areOthersMetaFetched: Bool = false
    private var _isArtURLFetched: Bool = false

    /// User data
    public var userData: Any?

    /// Parse status
    public var parseStatus: VLCMediaParsedStatus {
        guard let media = _media else { return .failed }
        return VLCMediaParsedStatus(rawValue: Int(libvlc_media_get_parsed_status(media).rawValue)) ?? .initial
    }

    /// Statistics
    public var statistics: VLCMediaStats {
        var stats = libvlc_media_stats_t()
        if let media = _media {
            libvlc_media_get_stats(media, &stats)
        }

        return VLCMediaStats(
            readBytes: stats.i_read_bytes,
            inputBitrate: stats.f_input_bitrate,
            demuxReadBytes: stats.i_demux_read_bytes,
            demuxBitrate: stats.f_demux_bitrate,
            demuxCorrupted: stats.i_demux_corrupted,
            demuxDiscontinuity: stats.i_demux_discontinuity,
            decodedVideo: stats.i_decoded_video,
            decodedAudio: stats.i_decoded_audio,
            displayedPictures: stats.i_displayed_pictures,
            lostPictures: stats.i_lost_pictures,
            playedAudioBuffers: stats.i_played_abuffers,
            lostAudioBuffers: stats.i_lost_abuffers,
            sentPackets: stats.i_sent_packets,
            sentBytes: stats.i_sent_bytes,
            sendBitrate: stats.f_send_bitrate
        )
    }

    /// Track information
    public var tracksInformation: [[String: Any]] {
        // Return empty array - track info requires parsing
        return []
    }

    /// Initialize
    public override init() {
        super.init()
        metaData = VLCMediaMetaData(media: self)
    }

    /// Initialize with URL
    public convenience init(url: URL) {
        self.init()
        _media = libvlc_media_new_location(VLCLibrary.sharedLibrary.instance, url.absoluteString)
        _metaDictionary = [:]
        initInternalMediaDescriptor()
    }

    /// Initialize with path
    public convenience init(path: String) {
        self.init(url: URL(fileURLWithPath: path, isDirectory: false))
    }

    /// Initialize with stream
    public convenience init(stream: InputStream) {
        self.init()
        _stream = stream
        // Note: libvlc_media_new_callbacks requires C function pointers
        _metaDictionary = [:]
    }

    /// Initialize as node
    public convenience init(nodeWithName name: String) {
        self.init()
        _media = libvlc_media_new_as_node(VLCLibrary.sharedLibrary.instance, name)
        _metaDictionary = [:]
        initInternalMediaDescriptor()
    }

    /// Initialize from a libvlc media descriptor
    public convenience init?(libVLCMediaDescriptor descriptor: OpaquePointer?) {
        guard let descriptor = descriptor else { return nil }
        self.init()
        _media = descriptor
        libvlc_media_retain(descriptor)
        _metaDictionary = [:]
        initInternalMediaDescriptor()
    }

    /// Initialize with media and options
    public convenience init(media: VLCMedia, andLibVLCOptions options: [String: String]) {
        self.init()
        if let desc = media.libVLCMediaDescriptor {
            _media = libvlc_media_duplicate(desc)
        }
        for (key, value) in options {
            let option = ":\(key)=\(value)"
            libvlc_media_add_option(_media, option)
        }
        _metaDictionary = [:]
        initInternalMediaDescriptor()
    }

    deinit {
        if let media = _media {
            libvlc_media_release(media)
        }
    }

    private func initInternalMediaDescriptor() {
        guard let media = _media else { return }
        state = VLCMediaState(rawValue: Int(libvlc_media_get_state(media).rawValue)) ?? .nothingSpecial

        let mrl = libvlc_media_get_mrl(media)
        if let mrl = mrl {
            let urlString = String(cString: mrl)
            self.url = URL(string: urlString) ?? URL(fileURLWithPath: urlString)
        }

        let mlist = libvlc_media_subitems(media)
        if let mlist = mlist {
            subitems = VLCMediaList(libVLCMediaList: mlist)
            libvlc_media_list_release(mlist)
        }
    }

    /// Parse media asynchronously
    public func parse() {
        guard let media = _media else { return }
        libvlc_media_parse_async(media)
    }

    /// Parse media with options
    @discardableResult
    public func parse(options: VLCMediaParsingOptions) -> Int {
        guard let media = _media else { return -1 }
        return Int(libvlc_media_parse_with_options(media, libvlc_media_parse_flag_t(rawValue: UInt32(options.rawValue)), -1))
    }

    /// Parse media with options and timeout
    @discardableResult
    public func parse(options: VLCMediaParsingOptions, timeout: Int) -> Int {
        guard let media = _media else { return -1 }
        return Int(libvlc_media_parse_with_options(media, libvlc_media_parse_flag_t(rawValue: UInt32(options.rawValue)), Int32(timeout)))
    }

    /// Stop parsing
    public func stopParse() {
        guard let media = _media else { return }
        libvlc_media_parse_stop(media)
    }

    /// Add option
    public func addOption(_ option: String) {
        guard let media = _media else { return }
        libvlc_media_add_option(media, option)
    }

    /// Add options
    public func addOptions(_ options: [String: String]) {
        options.forEach { key, value in
            let option = value.isEmpty ? key : "\(key)=\(value)"
            addOption(option)
        }
    }

    /// Store cookie
    public func storeCookie(_ cookie: String, forHost host: String, path: String) -> Int {
    #if os(iOS)
        guard let media = _media else { return -1 }
        return Int(libvlc_media_cookie_jar_store(media, cookie, host, path))
    #else
        return -1
    #endif
    }

    /// Clear stored cookies
    public func clearStoredCookies() {
    #if os(iOS)
        if let media = _media {
            libvlc_media_cookie_jar_clear(media)
        }
    #endif
    }

    /// Metadata for key
    @available(*, deprecated, message: "Use metaData instead")
    public func metadata(forKey key: String) -> String? {
        guard let media = _media else { return nil }
        let metaType = VLCMedia.stringToMetaType(key)
        guard let value = libvlc_media_get_meta(media, metaType) else { return nil }
        let result = String(cString: value)
        return result
    }

    /// Set metadata
    @available(*, deprecated, message: "Use metaData instead")
    public func setMetadata(_ data: String, forKey key: String) {
        guard let media = _media else { return }
        libvlc_media_set_meta(media, VLCMedia.stringToMetaType(key), data)
    }

    /// Save metadata
    @available(*, deprecated, message: "Use metaData.save() instead")
    public var saveMetadata: Bool {
        guard let media = _media else { return false }
        return libvlc_media_save_meta(media) != 0
    }

    /// Metadata dictionary
    @available(*, deprecated, message: "Use metaData instead")
    public var metaDictionary: [String: Any] {
        return _metaDictionary ?? [:]
    }

    /// Length wait until date
    public func length(waitUntilDate date: Date) -> VLCTime? {
        guard _media != nil, length == nil else { return length }

        parse()

        var status = parseStatus
        while length == nil && status != .failed && status != .done && date.timeIntervalSinceNow > 0 {
            usleep(10000)
            status = parseStatus
        }

        return length ?? VLCTime.nullTime()
    }

    /// Get media length asynchronously via completion handler
    public func length(completion: @escaping (VLCTime?) -> Void) {
        guard _media != nil else {
            completion(VLCTime.nullTime())
            return
        }

        if let existingLength = length {
            completion(existingLength)
            return
        }

        parse()

        let parseQueue = DispatchQueue(label: "org.videolan.media.lengthQueue", qos: .userInitiated)

        let checkTimer = DispatchSource.makeTimerSource(queue: parseQueue)
        checkTimer.schedule(deadline: .now() + 0.01, repeating: 0.1)
        checkTimer.setEventHandler { [weak self] in
            guard let self = self else {
                checkTimer.cancel()
                return
            }
            if self.length != nil || self.parseStatus == .failed || self.parseStatus == .done {
                checkTimer.cancel()
                DispatchQueue.main.async {
                    completion(self.length ?? VLCTime.nullTime())
                }
            }
        }
        checkTimer.resume()

        // Timeout after 30 seconds
        parseQueue.asyncAfter(deadline: .now() + 30) { [weak self] in
            checkTimer.cancel()
            DispatchQueue.main.async {
                completion(self?.length ?? VLCTime.nullTime())
            }
        }
    }

    /// Convert a string key to VLC media meta type
    static func stringToMetaType(_ key: String) -> libvlc_meta_t {
        switch key {
        case "title": return libvlc_meta_Title
        case "artist": return libvlc_meta_Artist
        case "genre": return libvlc_meta_Genre
        case "copyright": return libvlc_meta_Copyright
        case "album": return libvlc_meta_Album
        case "tracknumber": return libvlc_meta_TrackNumber
        case "description": return libvlc_meta_Description
        case "rating": return libvlc_meta_Rating
        case "date": return libvlc_meta_Date
        case "setting": return libvlc_meta_Setting
        case "url": return libvlc_meta_URL
        case "language": return libvlc_meta_Language
        case "nowplaying": return libvlc_meta_NowPlaying
        case "publisher": return libvlc_meta_Publisher
        case "encodedby": return libvlc_meta_EncodedBy
        case "artworkurl": return libvlc_meta_ArtworkURL
        case "trackid": return libvlc_meta_TrackID
        default: return libvlc_meta_Title
        }
    }
}
