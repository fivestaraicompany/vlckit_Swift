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
    case init = 0
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

      /// Check if media is suitable for device
      @available(*, deprecated, message: "This method is deprecated")
    public var mediaSizeSuitableForDevice: Bool {
     #if TARGET_OS_IPHONE
        var parsedStatus = parseStatus
        if parsedStatus == .skipped || parsedStatus == .init {
            parse(options: [.local, .network])
            sleep(2)
         }

        var biggestWidth: UInt = 0
        var biggestHeight: UInt = 0

        var tracksInfo: UnsafeMutablePointer<OpaquePointer?>?
        let count = libvlc_media_tracks_get(_media, &tracksInfo)

        for i in 0..<count {
            let track = tracksInfo![i].pointee
            guard let track = track else { continue }

            if track.pointee.i_type == libvlc_track_video {
                let video = track.pointee.u.pointee.video
                if video.i_width > biggestWidth { biggestWidth = video.i_width }
                if video.i_height > biggestHeight { biggestHeight = video.i_height }
              }
          }

        if biggestHeight > 0 && biggestWidth > 0 {
            let totalPixels = biggestWidth * biggestHeight

            var size = size_t(0)
            sysctlbyname("hw.machine", nil, &size, nil, 0)

            var answer = [CChar](repeating: 0, count: Int(size))
            sysctlbyname("hw.machine", &answer, &size, nil, 0)

            let currentMachine = String(cString: answer)
            answer.withUnsafeMutableBufferPointer { $0.deallocate() }

            if currentMachine.hasPrefix("iPhone2") || currentMachine.hasPrefix("iPhone3") ||
               currentMachine.hasPrefix("iPad1") || currentMachine.hasPrefix("iPod3") ||
               currentMachine.hasPrefix("iPod4") {
                return totalPixels < 600000
              } else if currentMachine.hasPrefix("iPhone4") || currentMachine.hasPrefix("iPad3,1") ||
                       currentMachine.hasPrefix("iPad3,2") || currentMachine.hasPrefix("iPad3,3") ||
                       currentMachine.hasPrefix("iPod4") || currentMachine.hasPrefix("iPad2") ||
                       currentMachine.hasPrefix("iPod5") {
                return totalPixels < 922000
              } else {
                return totalPixels < 2074000
             }
          }
        return true
     #else
        return true
     #endif
       }

      /// Compare media
    public func compare(_ media: VLCMedia?) -> ComparisonResult {
        guard let media = media else { return .orderedDescending }
        if self === media { return .orderedSame }
        return _media == media._media ? .orderedSame : .orderedAscending
       }

      /// Equal
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VLCMedia else { return false }
        return _media == other._media
       }

      /// Hash
    public override var hash: Int {
        return _media?.hashValue ?? 0
       }

      /// Description
    public override var description: String {
        let urlStr = url?.absoluteString.removingPercentEncoding ?? "nil"
        return "<\(type(of: self)) \(self), md: \(_media ?? UnsafeMutableRawPointer(bitPattern: 0xDEADBEEF)), url: \(urlStr)>"
       }

      /// Deinit
    deinit {
        if let media = _media {
            libvlc_media_release(media)
          }
       }

      // MARK: - Static Methods

      /// Create media from URL
    public static func media(withURL url: URL) -> VLCMedia {
        return VLCMedia(url: url)
       }

      /// Create media from path
    public static func media(withPath path: String) -> VLCMedia {
        return VLCMedia(path: path)
       }

      /// Create media as node
    public static func media(asNodeWithName name: String) -> VLCMedia {
        return VLCMedia(nodeWithName: name)
       }

      /// Get codec name for FourCC
    public static func codecName(forFourCC fourcc: UInt32, trackType: String) -> String {
        var trackTypeValue: libvlc_track_type_t = libvlc_track_unknown

        if trackType == "audio" {
            trackTypeValue = libvlc_track_audio
          } else if trackType == "video" {
            trackTypeValue = libvlc_track_video
          } else if trackType == "text" {
            trackTypeValue = libvlc_track_text
          }

        let ret = libvlc_media_get_codec_description(trackTypeValue, fourcc)
        guard let ret = ret else { return "" }
        let result = String(cString: ret)
        free(ret)
        return result
       }

      /// Track information
    public var tracksInformation: [[String: Any]] {
        var tracksInfo: UnsafeMutablePointer<OpaquePointer?>?
        let count = libvlc_media_tracks_get(_media, &tracksInfo)

        var array: [[String: Any]] = []

        for i in 0..<count {
            let track = tracksInfo![i].pointee
            guard let track = track else { continue }

            var dict: [String: Any] = [
                 "codec": NSNumber(value: track.pointee.i_codec),
                 "id": NSNumber(value: track.pointee.i_id),
                 "profile": NSNumber(value: track.pointee.i_profile),
                 "level": NSNumber(value: track.pointee.i_level),
                 "bitrate": NSNumber(value: track.pointee.i_bitrate)
             ]

            if let language = track.pointee.psz_language {
                dict["language"] = String(cString: language)
              }

            if let description = track.pointee.psz_description {
                dict["description"] = String(cString: description)
              }

            var type: String
            switch track.pointee.i_type {
            case libvlc_track_audio:
                type = "audio"
                dict["channelsNumber"] = NSNumber(value: track.pointee.u.audio.i_channels)
                dict["rate"] = NSNumber(value: track.pointee.u.audio.i_rate)
            case libvlc_track_video:
                type = "video"
                let video = track.pointee.u.video
                dict["height"] = NSNumber(value: video.i_height)
                dict["width"] = NSNumber(value: video.i_width)
                dict["orientation"] = NSNumber(value: video.i_orientation)
                dict["projection"] = NSNumber(value: video.i_projection)
                dict["sar_num"] = NSNumber(value: video.i_sar_num)
                dict["sar_den"] = NSNumber(value: video.i_sar_den)
                dict["frame_rate_num"] = NSNumber(value: video.i_frame_rate_num)
                dict["frame_rate_den"] = NSNumber(value: video.i_frame_rate_den)
            case libvlc_track_text:
                type = "text"
                if let encoding = track.pointee.u.subtitle.psz_encoding {
                    dict["encoding"] = String(cString: encoding)
                  }
            default:
                type = "unknown"
              }

            dict["type"] = type
            array.append(dict)
          }

        libvlc_media_tracks_release(tracksInfo, count)
        return array
       }

      // MARK: - Private Callbacks

    private static let openCallback: libvlc_media_open_cb = { opaque, datap, sizep in
        guard let opaque = opaque else { return -1 }

        let stream = Unmanaged<InputStream>.fromOpaque(opaque).takeUnretainedValue()

        datap?.pointee = opaque
        sizep?.pointee = UInt64.max

        if stream.streamStatus == .notOpen {
            stream.open()
          }

        return stream.streamStatus == .open ? 0 : -1
       }

    private static let readCallback: libvlc_media_read_cb = { opaque, buf, len in
        guard let opaque = opaque, let buf = buf else { return -1 }

        let stream = Unmanaged<InputStream>.fromOpaque(opaque).takeUnretainedValue()
        return stream.read(buf, maxLength: len)
       }

    private static let seekCallback: libvlc_media_seek_cb = { opaque, offset in
        guard let opaque = opaque else { return -1 }

        let stream = Unmanaged<InputStream>.fromOpaque(opaque).takeUnretainedValue()
        return stream.setProperty(offset, forKey: .fileCurrentOffset) ? 0 : -1
       }

    private static let closeCallback: libvlc_media_close_cb = { opaque in
        guard let opaque = opaque else { return }

        let stream = Unmanaged<InputStream>.fromOpaque(opaque).takeRetainedValue()
        if stream.streamStatus != .closed && stream.streamStatus != .notOpen {
            stream.close()
         }
       }

      // MARK: - Event Callbacks

    private static func mediaMetaChangedCallback(data: UnsafeMutableRawPointer?, event: UnsafePointer<libvlc_event_t>) {
        guard let data = data, let event = event else { return }

        let media = Unmanaged<VLCMedia>.fromOpaque(data).takeUnretainedValue()
        let metaType = NSNumber(value: event.pointee.u.media_meta_changed.meta_type)

        media.metaData.handleMediaMetaChanged(metaType: metaType.intValue)
        media.delegate?.mediaMetaDataDidChange(media)
       }

    private static func mediaDurationChangedCallback(data: UnsafeMutableRawPointer?, event: UnsafePointer<libvlc_event_t>) {
        guard let data = data, let event = event else { return }

        let media = Unmanaged<VLCMedia>.fromOpaque(data).takeUnretainedValue()
        let duration = VLCTime(timeWithNumber: NSNumber(value: event.pointee.u.media_duration_changed.new_duration))

        media.length = duration
       }

    private static func mediaStateChangedCallback(data: UnsafeMutableRawPointer?, event: UnsafePointer<libvlc_event_t>) {
        guard let data = data, let event = event else { return }

        let media = Unmanaged<VLCMedia>.fromOpaque(data).takeUnretainedValue()
        let state = VLCMediaState(rawValue: event.pointee.u.media_state_changed.new_state) ?? .nothingSpecial

        media.state = state
       }

    private static func mediaSubItemAddedCallback(data: UnsafeMutableRawPointer?, event: UnsafePointer<libvlc_event_t>) {
        guard let data = data, let event = event else { return }

        let media = Unmanaged<VLCMedia>.fromOpaque(data).takeUnretainedValue()

        let mlist = libvlc_media_subitems(media._media)
        if let mlist = mlist {
            media.subitems = VLCMediaList(mediaList: mlist)
            libvlc_media_list_release(mlist)
          }
       }

    private static func mediaParsedChangedCallback(data: UnsafeMutableRawPointer?, event: UnsafePointer<libvlc_event_t>) {
        guard let data = data else { return }

        let media = Unmanaged<VLCMedia>.fromOpaque(data).takeUnretainedValue()
        media.delegate?.mediaDidFinishParsing(media)
       }

      /// Legacy bridge methods
    public static func media(withMedia media: VLCMedia, andLibVLCOptions options: [String: String]) -> VLCMedia {
        let p_md = libvlc_media_duplicate(media._media)

        options.forEach { key, value in
            let option = value.isEmpty ? key : "\(key)=\(value)"
            libvlc_media_add_option(p_md, option)
         }

        return VLCMedia()
       }

    private func setLength(_ value: VLCTime?) {
        self.length = value
       }
}

// MARK: - Deprecated Extensions
extension VLCMedia {
      /// Stats
      @available(*, deprecated, message: "Use statistics instead")
    public var stats: [String: Any]? {
        let stats = self.statistics
        return [
             "demuxBitrate": stats.demuxBitrate,
             "inputBitrate": stats.inputBitrate,
             "sendBitrate": stats.sendBitrate,
             "decodedAudio": stats.decodedAudio,
             "decodedVideo": stats.decodedVideo,
             "demuxCorrupted": stats.demuxCorrupted,
             "demuxDiscontinuity": stats.demuxDiscontinuity,
             "demuxReadBytes": stats.demuxReadBytes,
             "displayedPictures": stats.displayedPictures,
             "lostAbuffers": stats.lostAudioBuffers,
             "lostPictures": stats.lostPictures,
             "playedAbuffers": stats.playedAudioBuffers,
             "readBytes": stats.readBytes,
             "sentBytes": stats.sentBytes,
             "sentPackets": stats.sentPackets
         ]
       }

      /// Deprecated stats properties
      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfReadBytesOnInput: Int32 { return statistics.readBytes }

      @available(*, deprecated, message: "Use statistics instead")
    public var inputBitrate: Float32 { return statistics.inputBitrate }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfReadBytesOnDemux: Int32 { return statistics.demuxReadBytes }

      @available(*, deprecated, message: "Use statistics instead")
    public var demuxBitrate: Float32 { return statistics.demuxBitrate }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfDecodedVideoBlocks: Int32 { return statistics.decodedVideo }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfDecodedAudioBlocks: Int32 { return statistics.decodedAudio }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfDisplayedPictures: Int32 { return statistics.displayedPictures }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfLostPictures: Int32 { return statistics.lostPictures }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfPlayedAudioBuffers: Int32 { return statistics.playedAudioBuffers }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfLostAudioBuffers: Int32 { return statistics.lostAudioBuffers }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfSentPackets: Int32 { return statistics.sentPackets }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfSentBytes: Int32 { return statistics.sentBytes }

      @available(*, deprecated, message: "Use statistics instead")
    public var streamOutputBitrate: Float32 { return statistics.sendBitrate }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfCorruptedDataPackets: Int32 { return statistics.demuxCorrupted }

      @available(*, deprecated, message: "Use statistics instead")
    public var numberOfDiscontinuties: Int32 { return statistics.demuxDiscontinuity }
}
