//
//  VLCMedia.swift
//  VLCKit
//
//  VLCMedia - Media object for VLC playback
//

import Foundation

/**
 Delegate for VLCMedia events
 */
public protocol VLCMediaDelegate: AnyObject {
      /// Called when media metadata changes
      /// - Parameter media: The media whose metadata changed
    func mediaMetaDataDidChange(_ media: VLCMedia)

      /// Called when media parsing is complete
      /// - Parameter media: The parsed media
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
public enum VLCMediaParsingOptions: Int {
    case local = 0x00
    case network = 0x01
    case fetchLocal = 0x02
    case fetchNetwork = 0x04
    case interact = 0x08
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
      /// Bytes read by the current input module
    public var readBytes: Int32 = 0

      /// Current input bitrate
    public var inputBitrate: Float32 = 0

      /// Bytes read by the current demux module
    public var demuxReadBytes: Int32 = 0

      /// Current demux bitrate
    public var demuxBitrate: Float32 = 0

      /// Corrupted data packets
    public var demuxCorrupted: Int32 = 0

      /// Discontinuities
    public var demuxDiscontinuity: Int32 = 0

      /// Decoded video blocks
    public var decodedVideo: Int32 = 0

      /// Decoded audio blocks
    public var decodedAudio: Int32 = 0

      /// Displayed pictures
    public var displayedPictures: Int32 = 0

      /// Lost pictures
    public var lostPictures: Int32 = 0

      /// Played audio buffers
    public var playedAudioBuffers: Int32 = 0

      /// Lost audio buffers
    public var lostAudioBuffers: Int32 = 0

      /// Sent packets
    public var sentPackets: Int32 = 0

      /// Sent bytes
    public var sentBytes: Int32 = 0

      /// Send bitrate
    public var sendBitrate: Float32 = 0
}

/**
 VLCMedia - Defines files and streams as a managed object
 */
public class VLCMedia: NSObject {

      /// Media delegate
    public weak var delegate: (any VLCMediaDelegate)? = nil

      /// Media length
    public var length: VLCTime? = nil {
        didSet {
            setLength(length)
         }
     }

      /// Media URL
    public private(set) var url: URL?

      /// Media state
    public private(set) var state: VLCMediaState = .nothingSpecial

      /// Media type
    public private(set) var mediaType: VLCMediaType = .unknown

      /// Subitems
    public private(set) var subitems: VLCMediaList? = nil

      /// Metadata
    public private(set) var metaData: VLCMediaMetaData

      /// Internal libvlc media descriptor
    private var _media: OpaquePointer?

      /// Stream for input
    private var _stream: InputStream?

      /// Metadata dictionary (deprecated)
    private var _metaDictionary: [String: Any]?

      /// Artwork fetched flag
    private var _isArtFetched: Bool = false

      /// Other metadata fetched flag
    private var _areOthersMetaFetched: Bool = false

      /// Art URL fetched flag
    private var _isArtURLFetched: Bool = false

      /// User data
    public var userData: Any?

      /// Parse status
    public var parseStatus: VLCMediaParsedStatus {
        guard let media = _media else { return .failed }
        return VLCMediaParsedStatus(rawValue: libvlc_media_get_parsed_status(media)) ?? .init
      }

      /// Statistics
    public var statistics: VLCMediaStats {
        var stats = libvlc_media_stats_t()
        libvlc_media_get_stats(_media, &stats)

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
          _media = libvlc_media_new_callbacks(
            VLCLibrary.sharedLibrary.instance,
            openCallback,
            readCallback,
            seekCallback,
            closeCallback,
            UnsafeMutableRawPointer(Unmanaged.passRetained(stream).toOpaque())
          )
          _metaDictionary = [:]
        initInternalMediaDescriptor()
       }

      /// Initialize as node
    public convenience init(nodeWithName name: String) {
        self.init()
          _media = libvlc_media_new_as_node(VLCLibrary.sharedLibrary.instance, name)
          _metaDictionary = [:]
        initInternalMediaDescriptor()
       }

      /// Initialize
    public override init() {
        self.metaData = VLCMediaMetaData(media: self)
        super.init()
       }

    private func initInternalMediaDescriptor() {
        state = VLCMediaState(rawValue: libvlc_media_get_state(_media)) ?? .nothingSpecial

        guard let url = String(cString: libvlc_media_get_mrl(_media)) else { return }

        self.url = URL(string: url) ?? URL(fileURLWithPath: url)

        let em = libvlc_media_event_manager(_media)
        if let em = em {
            let eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)
            let userData = UnsafeMutableRawPointer(Unmanaged.passRetained(eventsHandler).toOpaque())

            libvlc_event_attach(em, libvlc_MediaMetaChanged, mediaMetaChangedCallback, userData)
            libvlc_event_attach(em, libvlc_MediaDurationChanged, mediaDurationChangedCallback, userData)
            libvlc_event_attach(em, libvlc_MediaStateChanged, mediaStateChangedCallback, userData)
            libvlc_event_attach(em, libvlc_MediaSubItemAdded, mediaSubItemAddedCallback, userData)
            libvlc_event_attach(em, libvlc_MediaParsedChanged, mediaParsedChangedCallback, userData)
          }

        let mlist = libvlc_media_subitems(_media)
        if let mlist = mlist {
            subitems = VLCMediaList(mediaList: mlist)
            libvlc_media_list_release(mlist)
          }
       }

      /// Parse media asynchronously
    public func parse() {
        libvlc_media_parse_async(_media)
       }

      /// Parse media with options
    public func parse(options: VLCMediaParsingOptions) -> Int {
        guard let media = _media else { return -1 }
        return libvlc_media_parse_with_options(media, options.rawValue, -1)
       }

      /// Parse media with options and timeout
    public func parse(options: VLCMediaParsingOptions, timeout: Int) -> Int {
        guard let media = _media else { return -1 }
        return libvlc_media_parse_with_options(media, options.rawValue, timeout)
       }

      /// Stop parsing
    public func stopParse() {
        libvlc_media_parse_stop(_media)
       }

      /// Add option
    public func addOption(_ option: String) {
        libvlc_media_add_option(_media, option)
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
     #if TARGET_OS_IPHONE
        guard let media = _media else { return -1 }
        return libvlc_media_cookie_jar_store(media, cookie, host, path)
     #else
        return -1
     #endif
       }

      /// Clear stored cookies
    public func clearStoredCookies() {
     #if TARGET_OS_IPHONE
        libvlc_media_cookie_jar_clear(_media)
     #endif
       }

      /// Metadata for key
      @available(*, deprecated, message: "Use metaData instead")
    public func metadata(forKey key: String) -> String? {
        guard let media = _media else { return nil }
        let value = libvlc_media_get_meta(media, VLCMedia.stringToMetaType(key))
        guard let value = value else { return nil }
        let result = String(cString: value)
        free(value)
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
        return libvlc_media_save_meta(_media) != 0
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
            /// - Parameter completion: Completion handler with VLCTime? result
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
            let group = DispatchGroup()
            group.enter()

            let deadline = DispatchTime.now() + 30
            let timer = DispatchSource.makeTimerSource(queue: parseQueue)
            timer.schedule(deadline: deadline)
            timer.setEventHandler { [weak self] in
                group.leave()
            }
            timer.resume()

            /// Poll parse status with timeout
            let checkTimer = DispatchSource.makeTimerSource(queue: parseQueue)
            checkTimer.schedule(deadline: .now() + 0.01)
            checkTimer.setEventHandler { [weak self] in
                guard let self = self else { return }
                if self.length != nil || self.parseStatus == .failed || self.parseStatus == .done {
                    checkTimer.cancel()
                    group.leave()
                }
            }
            checkTimer.resume()

            group.notify(queue: .main) { [weak self] in
                completion(self?.length ?? VLCTime.nullTime())
            }
        }
        }
