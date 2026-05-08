//
//  VLCMediaPlayer.swift
//  VLCKit
//
//  VLCMediaPlayer - Media player
//

import Foundation
import CoreGraphics
import CLibVLC

/**
 Notification names
 */
public extension Notification.Name {
    static let VLCMediaPlayerTimeChanged = Notification.Name("VLCMediaPlayerTimeChanged")
    static let VLCMediaPlayerStateChanged = Notification.Name("VLCMediaPlayerStateChanged")
    static let VLCMediaPlayerTitleChanged = Notification.Name("VLCMediaPlayerTitleChanged")
    static let VLCMediaPlayerChapterChanged = Notification.Name("VLCMediaPlayerChapterChanged")
    static let VLCMediaPlayerLoudnessChanged = Notification.Name("VLCMediaPlayerLoudnessChanged")
    static let VLCMediaPlayerSnapshotTaken = Notification.Name("VLCMediaPlayerSnapshotTaken")
}

/**
 Title description keys
 */
public let VLCTitleDescriptionName = "VLCTitleDescriptionName"
public let VLCTitleDescriptionDuration = "VLCTitleDescriptionDuration"
public let VLCTitleDescriptionIsMenu = "VLCTitleDescriptionIsMenu"

/**
 Chapter description keys
 */
public let VLCChapterDescriptionName = "VLCChapterDescriptionName"
public let VLCChapterDescriptionTimeOffset = "VLCChapterDescriptionTimeOffset"
public let VLCChapterDescriptionDuration = "VLCChapterDescriptionDuration"

/**
 VLCMediaLoudness - Represents audio loudness information
 */
public class VLCMediaLoudness: NSObject {
    public private(set) var loudnessValue: Double = 0.0
    public private(set) var date: Int64 = 0

    public init(loudnessValue: Double, date: Int64) {
        self.loudnessValue = loudnessValue
        self.date = date
        super.init()
    }

    public static func loudness(value: Double, date: Int64) -> VLCMediaLoudness {
        return VLCMediaLoudness(loudnessValue: value, date: date)
    }

    public override var description: String {
        return "\(type(of: self)): value: \(loudnessValue), date: \(date)"
    }
}

/**
 Enum for media player state
 */
public enum VLCMediaPlayerState: Int {
    case stopped = 0
    case opening
    case buffering
    case ended
    case error
    case playing
    case paused
    case esAdded
}

/**
 Enum for media playback slave type
 */
public enum VLCMediaPlaybackSlaveType: Int {
    case subtitles = 0
    case audio
}

/**
 Enum for deinterlace mode
 */
public enum VLCDeinterlace: Int {
    case off = 0
    case on
    case auto
}

/**
 Enum for navigation actions
 */
public enum VLCMediaPlaybackNavigationAction: UInt {
    case activate = 0
    case up
    case down
    case left
    case right
}

/**
 Protocol for media player delegate
 */
public protocol VLCMediaPlayerDelegate: AnyObject {
    func mediaPlayerTimeChanged(_ notification: Notification)
    func mediaPlayerStateChanged(_ notification: Notification)
    func mediaPlayerTitleChanged(_ notification: Notification)
    func mediaPlayerChapterChanged(_ notification: Notification)
    func mediaPlayerLoudnessChanged(_ loudness: VLCMediaLoudness)
    func mediaPlayerSnapshot(_ fileName: String)
    func mediaPlayerStartedRecording(_ mediaPlayer: VLCMediaPlayer)
    func mediaPlayer(_ mediaPlayer: VLCMediaPlayer, recordingStoppedAtPath path: String)
}

/**
 VLCMediaPlayer - Media player for VLC playback
 */
public class VLCMediaPlayer: NSObject {

    public weak var delegate: (any VLCMediaPlayerDelegate)?

    public var libraryInstance: VLCLibrary?
    public private(set) var state: VLCMediaPlayerState = .stopped

    /// Current playback time. Setting this seeks libVLC to the new time.
    public var time: VLCTime? {
        get { _time }
        set {
            _time = newValue
            if let playerInstance = _playerInstance, let value = newValue?.value?.int64Value {
                libvlc_media_player_set_time(playerInstance, value)
            }
        }
    }
    private var _time: VLCTime?

    public private(set) var remainingTime: VLCTime?

    /// Current playback position (0.0–1.0). Setter seeks libVLC.
    public var position: Float {
        get { _position }
        set {
            _position = newValue
            if let playerInstance = _playerInstance {
                libvlc_media_player_set_position(playerInstance, newValue)
            }
        }
    }
    private var _position: Float = 0.0

    /// Current media. Setter forwards to libVLC and updates internal state.
    public var media: VLCMedia? {
        get { _media }
        set { setMedia(newValue) }
    }
    private var _media: VLCMedia?

    public private(set) var snapshots: [String] = []
    public private(set) var audio: VLCAudio?

    var playerInstance: OpaquePointer? {
        return _playerInstance
    }
    private var _playerInstance: OpaquePointer?
    private var _drawable: AnyObject?
    private var _libVLCBackgroundQueue: DispatchQueue?
    private var _eventsHandler: VLCEventsHandler?
    private var _viewpoint: OpaquePointer?
    private var _equalizer: VLCAudioEqualizer?

    /**
     Create a new media player
     */
    public override init() {
        super.init()
        initCommon()
        libraryInstance = VLCLibrary.sharedLibrary
        _playerInstance = libvlc_media_player_new(libraryInstance?.instance)
        ensureAudio()
        registerObservers()
    }

    /**
     Initialize with a library instance
     */
    public convenience init(library: VLCLibrary) {
        self.init()
        self.libraryInstance = library
        if let oldPlayer = _playerInstance {
            libvlc_media_player_release(oldPlayer)
        }
        _playerInstance = libvlc_media_player_new(library.instance)
        audio = nil
        ensureAudio()
    }

    /**
     Initialize with drawable and options
     */
    public convenience init(drawable: AnyObject?, options: [String]?) {
        self.init()

        if let options = options, !options.isEmpty {
            libraryInstance = VLCLibrary(options: options)
            if let oldPlayer = _playerInstance {
                libvlc_media_player_release(oldPlayer)
            }
            _playerInstance = libvlc_media_player_new(libraryInstance?.instance)
            audio = nil
            ensureAudio()
        }

        registerObservers()
        setDrawable(drawable)
    }

    private func initCommon() {
        _time = VLCTime.nullTime()
        remainingTime = VLCTime.nullTime()
        _libVLCBackgroundQueue = DispatchQueue(label: "libvlcQueue")
    }

    deinit {
        unregisterObservers()
        delegate = nil
        if let playerInstance = _playerInstance {
            libvlc_media_player_set_equalizer(playerInstance, nil)
            libvlc_media_player_release(playerInstance)
        }
        if let viewpoint = _viewpoint {
            libvlc_free(UnsafeMutableRawPointer(viewpoint))
        }
    }

    // MARK: - Drawable

    public var drawable: AnyObject? {
        get { return _drawable }
        set { setDrawable(newValue) }
    }

    private func setDrawable(_ drawable: AnyObject?) {
        _drawable = drawable
        guard let playerInstance = _playerInstance else { return }
        if let drawable = drawable {
            let drawablePtr = Unmanaged.passUnretained(drawable).toOpaque()
            libvlc_media_player_set_nsobject(playerInstance, drawablePtr)
        } else {
            libvlc_media_player_set_nsobject(playerInstance, nil)
        }
    }

    // MARK: - Audio

    public var audioPlayer: VLCAudio? {
        if audio == nil {
            audio = VLCAudio(mediaPlayerInstance: _playerInstance)
        }
        return audio
    }

    /// Lazily ensure `audio` is non-nil — ObjC parity (callers expect `player.audio?.volume = ...` to work)
    private func ensureAudio() {
        if audio == nil {
            audio = VLCAudio(mediaPlayerInstance: _playerInstance)
        }
    }

    // MARK: - Video Tracks

    public var numberOfVideoTracks: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_video_get_track_count(playerInstance))
    }

    public var currentVideoTrackIndex: Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let count = Int(libvlc_video_get_track_count(playerInstance))
        guard count > 0 else { return -1 }
        return Int(libvlc_video_get_track(playerInstance))
    }

    public func setVideoTrack(index: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_track(playerInstance, Int32(index))
    }

    public var videoTrackNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_video_get_track_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            if let pszName = track.pointee.psz_name {
                names.append(String(cString: pszName))
            }
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return names
    }

    /// Video track IDs as `[NSNumber]` — ObjC parity (callers `as? [NSNumber]` cast).
    public var videoTrackIndexes: [NSNumber] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [NSNumber] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_video_get_track_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            indexes.append(NSNumber(value: Int32(track.pointee.i_id)))
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return indexes
    }

    // MARK: - Subtitles

    public var numberOfSubtitlesTracks: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_video_get_spu_count(playerInstance))
    }

    /// Current subtitle track ID. `Int32` parity with the ObjC API.
    public var currentVideoSubTitleIndex: Int32 {
        get {
            guard let playerInstance = _playerInstance else { return -1 }
            let count = Int(libvlc_video_get_spu_count(playerInstance))
            guard count > 0 else { return -1 }
            return libvlc_video_get_spu(playerInstance)
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            libvlc_video_set_spu(playerInstance, newValue)
        }
    }

    public func setSubtitle(index: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_spu(playerInstance, Int32(index))
    }

    public var videoSubTitlesNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_spu_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_video_get_spu_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            if let pszName = track.pointee.psz_name {
                names.append(String(cString: pszName))
            }
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return names
    }

    /// Subtitle track IDs as `[NSNumber]` — ObjC parity.
    public var videoSubTitlesIndexes: [NSNumber] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_spu_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [NSNumber] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_video_get_spu_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            indexes.append(NSNumber(value: Int32(track.pointee.i_id)))
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return indexes
    }

    public func openVideoSubtitles(fromPath path: String) -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_add_slave(playerInstance,
                                             libvlc_media_slave_type_subtitle,
                                             path,
                                             true) == 0
    }

    public func addPlaybackSlave(_ slaveURL: URL, type: VLCMediaPlaybackSlaveType, enforce: Bool) -> Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let slaveType: libvlc_media_slave_type_t = type == .subtitles ? libvlc_media_slave_type_subtitle : libvlc_media_slave_type_audio
        return Int(libvlc_media_player_add_slave(playerInstance,
                                                 slaveType,
                                                 slaveURL.absoluteString,
                                                 enforce))
    }

    public var currentVideoSubTitleDelay: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_video_get_spu_delay(playerInstance))
    }

    public func setSubtitleDelay(_ delay: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_spu_delay(playerInstance, Int64(delay))
    }

    // MARK: - Video Crop & Aspect Ratio

    public var videoCropGeometry: String? {
        guard let playerInstance = _playerInstance else { return nil }
        guard let result = libvlc_video_get_crop_geometry(playerInstance) else { return nil }
        let str = String(cString: result)
        return str
    }

    public func setVideoCropGeometry(_ geometry: String) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_crop_geometry(playerInstance, geometry)
    }

    public var videoAspectRatio: String? {
        guard let playerInstance = _playerInstance else { return nil }
        guard let result = libvlc_video_get_aspect_ratio(playerInstance) else { return nil }
        let str = String(cString: result)
        return str
    }

    public func setVideoAspectRatio(_ aspectRatio: String) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_aspect_ratio(playerInstance, aspectRatio)
    }

    public var scaleFactor: Float {
        guard let playerInstance = _playerInstance else { return 0.0 }
        return libvlc_video_get_scale(playerInstance)
    }

    public func setScaleFactor(_ scale: Float) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_scale(playerInstance, scale)
    }

    public func saveVideoSnapshot(at path: String, width: Int, height: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_take_snapshot(playerInstance, 0, path, UInt32(width), UInt32(height))
    }

    public func setDeinterlace(_ deinterlace: VLCDeinterlace, withFilter filterName: String?) {
        guard let playerInstance = _playerInstance else { return }
        let filter = filterName ?? ""
        libvlc_video_set_deinterlace(playerInstance, Int32(deinterlace.rawValue), filter)
    }

    // MARK: - Video Size & Properties

    public var videoSize: CGSize {
        guard let playerInstance = _playerInstance else { return CGSize.zero }
        var width: UInt32 = 0
        var height: UInt32 = 0
        let failure = libvlc_video_get_size(playerInstance, 0, &width, &height)
        if failure != 0 {
            return CGSize.zero
        }
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }

    public var hasVideoOut: Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_has_vout(playerInstance) != 0
    }

    // MARK: - Playback Rate

    /// Playback rate (1.0 = normal). Setter forwards to libVLC.
    public var rate: Float {
        get {
            guard let playerInstance = _playerInstance else { return 0.0 }
            return libvlc_media_player_get_rate(playerInstance)
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            libvlc_media_player_set_rate(playerInstance, newValue)
        }
    }

    public func setRate(_ rate: Float) {
        self.rate = rate
    }

    // MARK: - Time & Position

    public func setTime(_ time: VLCTime) {
        self.time = time
    }

    public var timeValue: VLCTime? {
        return time
    }

    public var remainingTimeValue: VLCTime? {
        return remainingTime
    }

    // MARK: - Chapters

    public var currentChapterIndex: Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let count = Int(libvlc_media_player_get_chapter_count(playerInstance))
        guard count > 0 else { return -1 }
        return Int(libvlc_media_player_get_chapter(playerInstance))
    }

    public func setChapter(_ chapter: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_set_chapter(playerInstance, Int32(chapter))
    }

    public func nextChapter() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_next_chapter(playerInstance)
    }

    public func previousChapter() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_previous_chapter(playerInstance)
    }

    // MARK: - Titles

    public var currentTitleIndex: Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let count = Int(libvlc_media_player_get_title_count(playerInstance))
        guard count > 0 else { return -1 }
        return Int(libvlc_media_player_get_title(playerInstance))
    }

    public func setTitle(_ title: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_set_title(playerInstance, Int32(title))
    }

    public var numberOfTitles: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_media_player_get_title_count(playerInstance))
    }

    // MARK: - Audio Tracks

    public var numberOfAudioTracks: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_track_count(playerInstance))
    }

    /// Current audio track ID. `Int32` parity with the ObjC API.
    public var currentAudioTrackIndex: Int32 {
        get {
            guard let playerInstance = _playerInstance else { return -1 }
            let count = Int(libvlc_audio_get_track_count(playerInstance))
            guard count > 0 else { return -1 }
            return libvlc_audio_get_track(playerInstance)
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            libvlc_audio_set_track(playerInstance, newValue)
        }
    }

    public func setAudioTrack(index: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_track(playerInstance, Int32(index))
    }

    public var audioTrackNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_audio_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_audio_get_track_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            if let pszName = track.pointee.psz_name {
                names.append(String(cString: pszName))
            }
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return names
    }

    /// Audio track IDs as `[NSNumber]` — ObjC parity.
    public var audioTrackIndexes: [NSNumber] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_audio_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [NSNumber] = []
        var currentTrack: UnsafeMutablePointer<libvlc_track_description_t>? = libvlc_audio_get_track_description(playerInstance)
        let firstTrack = currentTrack
        while let track = currentTrack {
            indexes.append(NSNumber(value: Int32(track.pointee.i_id)))
            currentTrack = track.pointee.p_next
        }
        if let first = firstTrack {
            libvlc_track_description_list_release(first)
        }
        return indexes
    }

    public var audioChannel: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_channel(playerInstance))
    }

    public func setAudioChannel(_ channel: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_channel(playerInstance, Int32(channel))
    }

    public var currentAudioPlaybackDelay: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_delay(playerInstance))
    }

    public func setAudioPlaybackDelay(_ delay: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_delay(playerInstance, Int64(delay))
    }

    // MARK: - Equalizer

    public var equalizer: VLCAudioEqualizer? {
        get { return _equalizer }
        set {
            _equalizer?.mediaPlayer = nil
            _equalizer = newValue
            _equalizer?.mediaPlayer = self
        }
    }

    public var equalizerEnabled: Bool {
        return _equalizer != nil
    }

    // MARK: - Media

    public func setMedia(_ newMedia: VLCMedia?) {
        guard let newValue = newMedia else {
            _media = nil
            if let playerInstance = _playerInstance {
                libvlc_media_player_set_media(playerInstance, nil)
            }
            return
        }

        _media = newValue
        if let playerInstance = _playerInstance {
            libvlc_media_player_set_media(playerInstance, newValue.libVLCMediaDescriptor)
        }
    }

    // MARK: - Playback Control

    @discardableResult
    public func play() -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_play(playerInstance) == 0
    }

    public func pause() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_set_pause(playerInstance, 1)
    }

    public func stop() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_stop(playerInstance)
    }

    public func gotoNextFrame() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_next_frame(playerInstance)
    }

    public func fastForward() {
        fastForward(atRate: 2.0)
    }

    public func fastForward(atRate rate: Float) {
        setRate(rate)
    }

    public func rewind() {
        rewind(atRate: 2.0)
    }

    public func rewind(atRate rate: Float) {
        setRate(-rate)
    }

    public func jumpBackward(_ interval: Int) {
        guard isSeekable else { return }
        let intervalMs = interval * 1000
        let currentTime = timeValue?.intValue ?? 0
        setTime(VLCTime(timeWithInt: currentTime - intervalMs))
    }

    public func jumpForward(_ interval: Int) {
        guard isSeekable else { return }
        let intervalMs = interval * 1000
        let currentTime = timeValue?.intValue ?? 0
        setTime(VLCTime(timeWithInt: currentTime + intervalMs))
    }

    public func extraShortJumpBackward() { jumpBackward(3) }
    public func extraShortJumpForward() { jumpForward(3) }
    public func shortJumpBackward() { jumpBackward(10) }
    public func shortJumpForward() { jumpForward(10) }
    public func mediumJumpBackward() { jumpBackward(60) }
    public func mediumJumpForward() { jumpForward(60) }
    public func longJumpBackward() { jumpBackward(300) }
    public func longJumpForward() { jumpForward(300) }

    public func performNavigationAction(_ action: VLCMediaPlaybackNavigationAction) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_navigate(playerInstance, UInt32(action.rawValue))
    }

    public var isPlaying: Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_is_playing(playerInstance) != 0
    }

    public var willPlay: Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_will_play(playerInstance) != 0
    }

    public var isSeekable: Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_is_seekable(playerInstance) != 0
    }

    public var canPause: Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_can_pause(playerInstance) != 0
    }

    // MARK: - Snapshots

    public var snapshotsArray: [String] {
        return snapshots
    }

    public func lastSnapshot() -> String? {
        return snapshots.last
    }

    public func startRecording(atPath path: String) -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_record(playerInstance, true, path) != 0
    }

    public func stopRecording() -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_record(playerInstance, false, nil) != 0
    }

    // MARK: - Renderer

    public func setRendererItem(_ item: VLCRendererItem) -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        guard let rendererItem = item.libVLCRendererItem else { return false }
        return libvlc_media_player_set_renderer(playerInstance, rendererItem) == 0
    }

    // MARK: - Private Methods

    private func registerObservers() {
        guard let playerInstance = _playerInstance else { return }

        _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)

        guard let eventsManager = libvlc_media_player_event_manager(playerInstance) else { return }

        let userData = Unmanaged.passRetained(_eventsHandler!).toOpaque()

        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerPlaying.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerPaused.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerEncounteredError.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerEndReached.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerStopped.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerOpening.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerBuffering.rawValue), handleMediaPlayerEvent, userData)

        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerPositionChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerTimeChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerMediaChanged.rawValue), handleMediaPlayerEvent, userData)

        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerTitleChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerChapterChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_attach(eventsManager, Int32(libvlc_MediaPlayerSnapshotTaken.rawValue), handleMediaPlayerEvent, userData)
    }

    private func unregisterObservers() {
        guard let playerInstance = _playerInstance,
              let eventsManager = libvlc_media_player_event_manager(playerInstance),
              let eventsHandler = _eventsHandler else { return }

        let userData = Unmanaged.passRetained(eventsHandler).toOpaque()

        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerPlaying.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerPaused.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerEncounteredError.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerEndReached.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerStopped.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerOpening.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerBuffering.rawValue), handleMediaPlayerEvent, userData)

        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerPositionChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerTimeChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerMediaChanged.rawValue), handleMediaPlayerEvent, userData)

        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerTitleChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerChapterChanged.rawValue), handleMediaPlayerEvent, userData)
        libvlc_event_detach(eventsManager, Int32(libvlc_MediaPlayerSnapshotTaken.rawValue), handleMediaPlayerEvent, userData)

        _eventsHandler = nil
    }

    func handleTimeChanged(_ newTime: NSNumber) {
        _time = VLCTime(timeWithNumber: newTime)

        let currentTime = Double(truncating: newTime) / 1000.0
        if currentTime > 0 && _position > 0.0 {
            let remaining = currentTime / Double(_position) * Double(1.0 - _position)
            remainingTime = VLCTime(timeWithInt: Int64(-remaining * 1000))
        } else {
            remainingTime = VLCTime.nullTime()
        }
    }

    func handlePositionChanged(_ newPosition: NSNumber) {
        _position = newPosition.floatValue
    }

    func handleStateChanged(_ newState: VLCMediaPlayerState) {
        state = newState
    }

    func handleMediaChanged(_ newMedia: VLCMedia?) {
        if let newMedia = newMedia, _media !== newMedia {
            _media = newMedia
            _time = VLCTime.nullTime()
            remainingTime = VLCTime.nullTime()
            _position = 0.0
        }
    }

    func handleSnapshot(_ fileName: String) {
        snapshots.append(fileName)
    }
}

// MARK: - VLCMediaPlayer Event Callback

private let handleMediaPlayerEvent: @convention(c) (UnsafePointer<libvlc_event_t>?, UnsafeMutableRawPointer?) -> Void = { p_event, userData in
    guard let event = p_event?.pointee, let userData = userData else { return }
    let eventsHandler = Unmanaged<VLCEventsHandler>.fromOpaque(userData).takeUnretainedValue()

    eventsHandler.handleEvent { object in
        guard let mediaPlayer = object as? VLCMediaPlayer else { return }

        let eventType = UInt32(event.type)

        switch eventType {
        case libvlc_MediaPlayerPlaying.rawValue:
            mediaPlayer.handleStateChanged(.playing)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerPaused.rawValue:
            mediaPlayer.handleStateChanged(.paused)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerStopped.rawValue:
            mediaPlayer.handleStateChanged(.stopped)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerEncounteredError.rawValue:
            mediaPlayer.handleStateChanged(.error)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerEndReached.rawValue:
            mediaPlayer.handleStateChanged(.ended)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerOpening.rawValue:
            mediaPlayer.handleStateChanged(.opening)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerBuffering.rawValue:
            mediaPlayer.handleStateChanged(.buffering)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerESAdded.rawValue:
            mediaPlayer.handleStateChanged(.esAdded)
            let notification = Notification(name: .VLCMediaPlayerStateChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerStateChanged(notification)

        case libvlc_MediaPlayerPositionChanged.rawValue:
            let newPosition = NSNumber(value: event.u.media_player_position_changed.new_position)
            mediaPlayer.handlePositionChanged(newPosition)

        case libvlc_MediaPlayerTimeChanged.rawValue:
            let newTime = NSNumber(value: event.u.media_player_time_changed.new_time)
            mediaPlayer.handleTimeChanged(newTime)
            let notification = Notification(name: .VLCMediaPlayerTimeChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerTimeChanged(notification)

        case libvlc_MediaPlayerMediaChanged.rawValue:
            let newMedia = VLCMedia(libVLCMediaDescriptor: event.u.media_player_media_changed.new_media)
            mediaPlayer.handleMediaChanged(newMedia)

        case libvlc_MediaPlayerTitleChanged.rawValue:
            let notification = Notification(name: .VLCMediaPlayerTitleChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerTitleChanged(notification)

        case libvlc_MediaPlayerChapterChanged.rawValue:
            let notification = Notification(name: .VLCMediaPlayerChapterChanged, object: mediaPlayer)
            NotificationCenter.default.post(notification)
            mediaPlayer.delegate?.mediaPlayerChapterChanged(notification)

        case libvlc_MediaPlayerSnapshotTaken.rawValue:
            if let psz_filename = event.u.media_player_snapshot_taken.psz_filename {
                let fileName = String(cString: psz_filename)
                mediaPlayer.handleSnapshot(fileName)
                let notification = Notification(name: .VLCMediaPlayerSnapshotTaken, object: mediaPlayer)
                NotificationCenter.default.post(notification)
                mediaPlayer.delegate?.mediaPlayerSnapshot(fileName)
            }

        default:
            break
        }
    }
}

// MARK: - Helper Structs

public struct VLCMediaPlayerRecordEvent {
    public var recording: Bool
    public var filePath: String?

    public init(recording: Bool, filePath: String?) {
        self.recording = recording
        self.filePath = filePath
    }
}
