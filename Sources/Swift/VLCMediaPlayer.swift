//
//  VLCMediaPlayer.swift
//  VLCKit
//
//  VLCMediaPlayer - Media player
//

import Foundation

/**
 Notification name for time changes
 */
public let VLCMediaPlayerTimeChanged = "VLCMediaPlayerTimeChanged"

/**
 Notification name for state changes
 */
public let VLCMediaPlayerStateChanged = "VLCMediaPlayerStateChanged"

/**
 Notification name for title changes
 */
public let VLCMediaPlayerTitleChanged = "VLCMediaPlayerTitleChanged"

/**
 Notification name for chapter changes
 */
public let VLCMediaPlayerChapterChanged = "VLCMediaPlayerChapterChanged"

/**
 Notification name for loudness changes
 */
public let VLCMediaPlayerLoudnessChanged = "VLCMediaPlayerLoudnessChanged"

/**
 Notification name for snapshot taken
 */
public let VLCMediaPlayerSnapshotTaken = "VLCMediaPlayerSnapshotTaken"

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
public enum VLCMediaPlaybackNavigationAction: Int {
    case activate = 0
    case deactivate
    case menuUp
    case menuDown
    case menuLeft
    case menuRight
    case select
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

    public weak var delegate: (any VLCMediaPlayerDelegate)? = nil

    public var libraryInstance: VLCLibrary?
    public private(set) var state: VLCMediaPlayerState = .stopped
    public private(set) var time: VLCTime? = nil
    public private(set) var remainingTime: VLCTime? = nil
    public private(set) var position: Float = 0.0
    public private(set) var media: VLCMedia? = nil
    public private(set) var snapshots: [String] = []
    public private(set) var audio: VLCAudio?

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
    }

    /**
     Initialize with a library instance

     - Parameter library: The library instance to use
     - Returns: A new media player instance
     */
    public convenience init(library: VLCLibrary) {
        self.init()
        self.libraryInstance = library
        _playerInstance = libvlc_media_player_new(library.instance)
        guard let playerInstance = _playerInstance else {
            fatalError("Media player initialization failed")
        }
        registerObservers()
    }

    /**
     Initialize with a libvlc instance and library

     - Parameters:
       - playerInstance: The libvlc media player instance
       - library: The library instance
     - Returns: A new media player instance
     */
    public init(playerInstance: OpaquePointer, library: VLCLibrary) {
        super.init()
        initCommon()
        self.libraryInstance = library
        _playerInstance = playerInstance
        registerObservers()
    }

    /**
     Initialize with drawable and options

     - Parameters:
       - drawable: The drawable object
       - options: Array of options
     - Returns: A new media player instance
     */
    public convenience init(drawable: AnyObject?, options: [String]?) {
        self.init()

        if let options = options, !options.isEmpty {
            libraryInstance = VLCLibrary(options: options)
            _playerInstance = libvlc_media_player_new(libraryInstance?.instance)
        } else {
            libraryInstance = VLCLibrary.sharedLibrary
            _playerInstance = libvlc_media_player_new(libraryInstance?.instance)
        }

        guard let playerInstance = _playerInstance else {
            fatalError("Media player initialization failed")
        }

        registerObservers()
        setDrawable(drawable)
    }

    private func initCommon() {
        time = VLCTime.nullTime()
        remainingTime = VLCTime.nullTime()
        _libVLCBackgroundQueue = DispatchQueue(label: "libvlcQueue", attributes: .serial)
    }

    deinit {
        unregisterObservers()
        delegate = nil
        libvlc_media_player_set_nsobject(_playerInstance, nil)
        libvlc_media_player_set_equalizer(_playerInstance, nil)
        if let viewpoint = _viewpoint {
            libvlc_free(viewpoint)
            _viewpoint = nil
        }
        _playerInstance = nil
    }

    // MARK: - Drawable

    public var drawable: AnyObject? {
        get { return _drawable }
        set { setDrawable(newValue) }
    }

    private func setDrawable(_ drawable: AnyObject?) {
        _drawable = drawable
        if let playerInstance = _playerInstance {
            let drawablePtr = drawable.flatMap { Unmanaged.passUnretained($0).toOpaque() }
            libvlc_media_player_set_nsobject(playerInstance, drawablePtr)
        }
    }

    // MARK: - Audio

    public var audioPlayer: VLCAudio {
        if audio == nil {
            audio = VLCAudio(mediaPlayerInstance: _playerInstance)
        }
        return audio!
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
        libvlc_video_set_track(playerInstance, index)
    }

    public var videoTrackNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        if let firstTrack = libvlc_video_get_track_description(playerInstance) {
            var currentTrack = firstTrack
            while currentTrack.pointee.psz_name != nil {
                names.append(String(cString: currentTrack.pointee.psz_name))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return names
    }

    public var videoTrackIndexes: [Int] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [Int] = []
        if let firstTrack = libvlc_video_get_track_description(playerInstance) {
            var currentTrack = firstTrack
            while currentTrack.pointee.psz_name != nil {
                indexes.append(Int(currentTrack.pointee.i_id))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return indexes
    }

    // MARK: - Subtitles

    public var numberOfSubtitlesTracks: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_video_get_spu_count(playerInstance))
    }

    public var currentVideoSubTitleIndex: Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let count = Int(libvlc_video_get_spu_count(playerInstance))
        guard count > 0 else { return -1 }
        return Int(libvlc_video_get_spu(playerInstance))
    }

    public func setSubtitle(index: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_spu(playerInstance, index)
    }

    public var videoSubTitlesNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_spu_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        if let firstTrack = libvlc_video_get_spu_description(playerInstance) {
            var currentTrack = firstTrack
            while currentTrack.pointee.psz_name != nil {
                names.append(String(cString: currentTrack.pointee.psz_name))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return names
    }

    public var videoSubTitlesIndexes: [Int] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_video_get_spu_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [Int] = []
        if let firstTrack = libvlc_video_get_spu_description(playerInstance) {
            var currentTrack = firstTrack
            while currentTrack.pointee.psz_name != nil {
                indexes.append(Int(currentTrack.pointee.i_id))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return indexes
    }

    public func openVideoSubtitles(fromPath path: String) -> Bool {
        guard let playerInstance = _playerInstance else { return false }
        return libvlc_media_player_add_slave(playerInstance,
                                             libvlc_media_slave_type_subtitle,
                                             path,
                                             true) != 0
    }

    public func addPlaybackSlave(_ slaveURL: URL, type: VLCMediaPlaybackSlaveType, enforce: Bool) -> Int {
        guard let playerInstance = _playerInstance else { return -1 }
        return libvlc_media_player_add_slave(playerInstance,
                                             type.rawValue,
                                             slaveURL.absoluteString,
                                             enforce)
    }

    public var currentVideoSubTitleDelay: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_video_get_spu_delay(playerInstance))
    }

    public func setSubtitleDelay(_ delay: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_video_set_spu_delay(playerInstance, delay)
    }

    // MARK: - Video Crop & Aspect Ratio

    public var videoCropGeometry: String? {
        guard let playerInstance = _playerInstance else { return nil }
        guard let result = libvlc_video_get_crop_geometry(playerInstance) else { return nil }
        let str = String(cString: result)
        libvlc_free(result)
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
        libvlc_free(result)
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
        let failure = libvlc_video_take_snapshot(playerInstance, 0, path, width, height)
        if failure != 0 {
            fatalError("Can't take a video snapshot - No video output")
        }
    }

    public func setDeinterlace(_ deinterlace: VLCDeinterlace, withFilter filterName: String?) {
        guard let playerInstance = _playerInstance else { return }
        let filter = filterName ?? ""
        libvlc_video_set_deinterlace(playerInstance, deinterlace.rawValue, filter)
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

    public var rate: Float {
        guard let playerInstance = _playerInstance else { return 0.0 }
        return libvlc_media_player_get_rate(playerInstance)
    }

    public func setRate(_ rate: Float) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_set_rate(playerInstance, rate)
    }

    // MARK: - Time & Position

    public func setTime(_ time: VLCTime) {
        guard let playerInstance = _playerInstance else { return }
        let timeValue = time.value?.int64Value ?? 0
        libvlc_media_player_set_time(playerInstance, timeValue)
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
        libvlc_media_player_set_chapter(playerInstance, chapter)
    }

    public func nextChapter() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_next_chapter(playerInstance)
    }

    public func previousChapter() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_previous_chapter(playerInstance)
    }

    public func chapters(forTitle titleIndex: Int) -> [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_media_player_get_chapter_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        if let firstTrack = libvlc_video_get_chapter_description(playerInstance, titleIndex) {
            var currentTrack = firstTrack
            for _ in 0..<count {
                if let psz_name = currentTrack.pointee.psz_name {
                    names.append(String(cString: psz_name))
                }
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return names
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
        libvlc_media_player_set_title(playerInstance, title)
    }

    public var numberOfTitles: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_media_player_get_title_count(playerInstance))
    }

    public var titles: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_media_player_get_title_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        if let firstTrack = libvlc_video_get_title_description(playerInstance) {
            var currentTrack = firstTrack
            while let psz_name = currentTrack.pointee.psz_name {
                names.append(String(cString: psz_name))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return names
    }

    public func titleDescriptions() -> [[String: Any]] {
        guard let playerInstance = _playerInstance else { return [] }

        var titleInfo: OpaquePointer? = nil
        let numberOfTitleDescriptions = libvlc_media_player_get_full_title_descriptions(playerInstance, &titleInfo)

        guard numberOfTitleDescriptions > 0 else {
            return []
        }

        var array: [[String: Any]] = []
        for i in 0..<numberOfTitleDescriptions {
            guard let titlePtr = UnsafeMutablePointer<libvlc_title_description_t>(OpaquePointer(titleInfo) + i) else { continue }

            var dictionary: [String: Any] = [
                VLCTitleDescriptionDuration: titlePtr.pointee.i_duration,
                VLCTitleDescriptionIsMenu: (titlePtr.pointee.i_flags & libvlc_title_menu) != 0
            ]

            if let psz_name = titlePtr.pointee.psz_name {
                dictionary[VLCTitleDescriptionName] = String(cString: psz_name)
            }

            array.append(dictionary)
        }

        libvlc_title_descriptions_release(titleInfo, numberOfTitleDescriptions)
        return array
    }

    public func indexOfLongestTitle() -> Int {
        let titles = titleDescriptions()
        guard !titles.isEmpty else { return 0 }

        var currentlyFoundTitle = 0
        var currentlySelectedDuration: Int64 = 0

        for (x, title) in titles.enumerated() {
            if let duration = title[VLCTitleDescriptionDuration] as? Int64, duration > currentlySelectedDuration {
                currentlySelectedDuration = duration
                currentlyFoundTitle = x
            }
        }

        return currentlyFoundTitle
    }

    public func numberOfChapters(forTitle titleIndex: Int) -> Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_media_player_get_chapter_count_for_title(playerInstance, titleIndex))
    }

    public func chapterDescriptions(forTitle titleIndex: Int) -> [[String: Any]] {
        guard let playerInstance = _playerInstance else { return [] }

        var chapterDescriptions: OpaquePointer? = nil
        let numberOfChapterDescriptions = libvlc_media_player_get_full_chapter_descriptions(playerInstance, titleIndex, &chapterDescriptions)

        guard numberOfChapterDescriptions > 0 else {
            return []
        }

        var array: [[String: Any]] = []
        for i in 0..<numberOfChapterDescriptions {
            guard let chapterPtr = UnsafeMutablePointer<libvlc_chapter_description_t>(OpaquePointer(chapterDescriptions) + i) else { continue }

            var dictionary: [String: Any] = [
                VLCChapterDescriptionDuration: chapterPtr.pointee.i_duration,
                VLCChapterDescriptionTimeOffset: chapterPtr.pointee.i_time_offset
            ]

            if let psz_name = chapterPtr.pointee.psz_name {
                dictionary[VLCChapterDescriptionName] = String(cString: psz_name)
            }

            array.append(dictionary)
        }

        libvlc_chapter_descriptions_release(chapterDescriptions, numberOfChapterDescriptions)
        return array
    }

    // MARK: - Audio Tracks

    public var numberOfAudioTracks: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_track_count(playerInstance))
    }

    public var currentAudioTrackIndex: Int {
        guard let playerInstance = _playerInstance else { return -1 }
        let count = Int(libvlc_audio_get_track_count(playerInstance))
        guard count > 0 else { return -1 }
        return Int(libvlc_audio_get_track(playerInstance))
    }

    public func setAudioTrack(index: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_track(playerInstance, index)
    }

    public var audioTrackNames: [String] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_audio_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var names: [String] = []
        if let firstTrack = libvlc_audio_get_track_description(playerInstance) {
            var currentTrack = firstTrack
            while let psz_name = currentTrack.pointee.psz_name {
                names.append(String(cString: psz_name))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return names
    }

    public var audioTrackIndexes: [Int] {
        guard let playerInstance = _playerInstance else { return [] }
        let count = Int(libvlc_audio_get_track_count(playerInstance))
        guard count > 0 else { return [] }

        var indexes: [Int] = []
        if let firstTrack = libvlc_audio_get_track_description(playerInstance) {
            var currentTrack = firstTrack
            while let psz_name = currentTrack.pointee.psz_name {
                indexes.append(Int(currentTrack.pointee.i_id))
                currentTrack = currentTrack.pointee.p_next ?? nil
            }
            libvlc_track_description_list_release(firstTrack)
        }
        return indexes
    }

    public var audioChannel: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_channel(playerInstance))
    }

    public func setAudioChannel(_ channel: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_channel(playerInstance, channel)
    }

    public var currentAudioPlaybackDelay: Int {
        guard let playerInstance = _playerInstance else { return 0 }
        return Int(libvlc_audio_get_delay(playerInstance))
    }

    public func setAudioPlaybackDelay(_ delay: Int) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_audio_set_delay(playerInstance, delay)
    }

    public var momentaryLoudness: VLCMediaLoudness? {
        return _equalizer?.momentaryLoudness
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

    public func setEqualizerEnabled(_ enabled: Bool) {
        if enabled && _equalizer == nil {
            _equalizer = VLCAudioEqualizer()
        } else if !enabled {
            _equalizer = nil
        }
    }

    public var equalizerProfiles: [String] {
        let count = libvlc_audio_equalizer_get_preset_count()
        var profiles: [String] = []
        for x in 0..<count {
            if let name = libvlc_audio_equalizer_get_preset_name(x) {
                profiles.append(String(cString: name))
            }
        }
        return profiles
    }

    public func resetEqualizer(fromProfile profile: UInt) {
        // Simplified - actual implementation would require VLCAudioEqualizer setup
    }

    public var preAmplification: Float {
        return _equalizer?.preAmplification ?? 0.0
    }

    public func setPreAmplification(_ value: Float) {
        if _equalizer == nil {
            _equalizer = VLCAudioEqualizer()
        }
        _equalizer?.preAmplification = value
    }

    public var numberOfBands: UInt {
        return libvlc_audio_equalizer_get_band_count()
    }

    public func frequencyOfBand(atIndex index: UInt) -> Float {
        return libvlc_audio_equalizer_get_band_frequency(index)
    }

    public func setAmplification(_ value: Float, forBand index: UInt) {
        if _equalizer == nil {
            _equalizer = VLCAudioEqualizer()
        }
        _equalizer?.bands.first { $0.index == index }?.amplification = value
    }

    public func amplificationOfBand(atIndex index: UInt) -> Float {
        return _equalizer?.bands.first { $0.index == index }?.amplification ?? 0.0
    }

    // MARK: - Media

    public var mediaPlayer: VLCMedia? {
        get { return media }
        set {
            guard let newValue = newValue else {
                if media != nil {
                    media = nil
                    libvlc_media_player_set_media_async(_playerInstance, nil)
                }
                return
            }

            if media != nil && media?.compare(newValue) == .orderedSame {
                return
            }

            media = newValue
            if let media = media {
                libvlc_media_player_set_media_async(_playerInstance, media.libVLCMediaDescriptor)
            }
        }
    }

    // MARK: - Playback Control

    public func play() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_play(playerInstance)
    }

    public func pause() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_set_pause(playerInstance, 1)
    }

    public func stop() {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_stop_async(playerInstance)
    }

    public func viewPoint() -> VLCVideoViewpoint {
        if let viewpoint = _viewpoint {
            return VLCVideoViewpoint(yaw: viewpoint.pointee.f_yaw,
                                     pitch: viewpoint.pointee.f_pitch,
                                     roll: viewpoint.pointee.f_roll,
                                     fov: viewpoint.pointee.f_field_of_view)
        }

        let newViewpoint = libvlc_video_new_viewpoint()
        _viewpoint = newViewpoint
        return VLCVideoViewpoint(yaw: newViewpoint.pointee.f_yaw,
                                 pitch: newViewpoint.pointee.f_pitch,
                                 roll: newViewpoint.pointee.f_roll,
                                 fov: newViewpoint.pointee.f_field_of_view)
    }

    public func updateViewpoint(yaw: Float, pitch: Float, roll: Float, fov: Float, absolute: Bool) -> Bool {
        var viewpoint = viewPoint()
        viewpoint.yaw = yaw
        viewpoint.pitch = pitch
        viewpoint.roll = roll
        viewpoint.fov = fov

        guard let playerInstance = _playerInstance else { return false }
        return libvlc_video_update_viewpoint(playerInstance, viewpoint.ptr, absolute) == 0
    }

    public var yaw: Float {
        return viewPoint().yaw
    }

    public var pitch: Float {
        return viewPoint().pitch
    }

    public var roll: Float {
        return viewPoint().roll
    }

    public var fov: Float {
        return viewPoint().fov
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

    public func extraShortJumpBackward() {
        jumpBackward(3)
    }

    public func extraShortJumpForward() {
        jumpForward(3)
    }

    public func shortJumpBackward() {
        jumpBackward(10)
    }

    public func shortJumpForward() {
        jumpForward(10)
    }

    public func mediumJumpBackward() {
        jumpBackward(60)
    }

    public func mediumJumpForward() {
        jumpForward(60)
    }

    public func longJumpBackward() {
        jumpBackward(300)
    }

    public func longJumpForward() {
        jumpForward(300)
    }

    public func performNavigationAction(_ action: VLCMediaPlaybackNavigationAction) {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_navigate(playerInstance, action.rawValue)
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
        guard !snapshots.isEmpty else { return nil }
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
        return libvlc_media_player_set_renderer(playerInstance, item.libVLCRendererItem) == 0
    }

    // MARK: - Private Methods

    private func registerObservers() {
        guard let playerInstance = _playerInstance else { return }

        _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)

        let eventsManager = libvlc_media_player_event_manager(playerInstance)
        guard let eventsManager = eventsManager else { return }

        let userData = Unmanaged.passRetained(_eventsHandler!).toOpaque()

        _libVLCBackgroundQueue?.async {
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerPlaying, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerPaused, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerEncounteredError, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerEndReached, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerStopped, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerOpening, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerBuffering, HandleMediaInstanceStateChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerESAdded, HandleMediaInstanceStateChanged, userData)

            libvlc_event_attach(eventsManager, libvlc_MediaPlayerPositionChanged, HandleMediaPositionChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerTimeChanged, HandleMediaTimeChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerMediaChanged, HandleMediaPlayerMediaChanged, userData)

            libvlc_event_attach(eventsManager, libvlc_MediaPlayerTitleChanged, HandleMediaTitleChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerChapterChanged, HandleMediaChapterChanged, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerLoudnessChanged, HandleMediaLoudnessChanged, userData)

            libvlc_event_attach(eventsManager, libvlc_MediaPlayerSnapshotTaken, HandleMediaPlayerSnapshot, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerRecordChanged, HandleMediaPlayerRecord, userData)
        }
    }

    private func unregisterObservers() {
        _eventsHandler = nil

        guard let playerInstance = _playerInstance else { return }
        let eventsManager = libvlc_media_player_event_manager(playerInstance)
        guard let eventsManager = eventsManager else { return }

        let userData = _eventsHandler.map { Unmanaged.passRetained($0).toOpaque() }

        _libVLCBackgroundQueue?.async {
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerPlaying, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerPaused, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerEncounteredError, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerEndReached, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerStopped, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerOpening, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerBuffering, HandleMediaInstanceStateChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerESAdded, HandleMediaInstanceStateChanged, userData)

            libvlc_event_detach(eventsManager, libvlc_MediaPlayerPositionChanged, HandleMediaPositionChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerTimeChanged, HandleMediaTimeChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerMediaChanged, HandleMediaPlayerMediaChanged, userData)

            libvlc_event_detach(eventsManager, libvlc_MediaPlayerTitleChanged, HandleMediaTitleChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerChapterChanged, HandleMediaChapterChanged, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerLoudnessChanged, HandleMediaLoudnessChanged, userData)

            libvlc_event_detach(eventsManager, libvlc_MediaPlayerSnapshotTaken, HandleMediaPlayerSnapshot, userData)
            libvlc_event_detach(eventsManager, libvlc_MediaPlayerRecordChanged, HandleMediaPlayerRecord, userData)
        }
    }

    private func handleTimeChanged(_ newTime: NSNumber) {
        time = VLCTime(timeWithNumber: newTime)

        let currentTime = Double(newTime.int64Value) / 1000.0
        if currentTime > 0 && position > 0.0 {
            let remaining = currentTime / position * (1.0 - position)
            remainingTime = VLCTime(timeWithInt: Int64(-remaining * 1000))
        } else {
            remainingTime = VLCTime.nullTime()
        }
    }

    private func handlePositionChanged(_ newPosition: NSNumber) {
        position = newPosition.floatValue
    }

    private func handleStateChanged(_ newState: NSNumber) {
        let rawValue = newState.intValue
        state = VLCMediaPlayerState(rawValue: rawValue) ?? .stopped
    }

    private func handleMediaChanged(_ newMedia: VLCMedia) {
        if media != newMedia {
            media = newMedia
            time = VLCTime.nullTime()
            remainingTime = VLCTime.nullTime()
            position = 0.0
        }
    }

    private func handleTitleChanged(_ newTitle: NSNumber) {
        // Title index changed
    }

    private func handleChapterChanged(_ newChapter: NSNumber) {
        // Chapter index changed
    }

    private func handleLoudnessChanged(_ newLoudness: VLCMediaLoudness) {
        _equalizer?.momentaryLoudness = newLoudness
    }

    private func handleSnapshot(_ fileName: String) {
        snapshots.append(fileName)
    }

    private func handleRecord(_ event: VLCMediaPlayerRecordEvent) {
        if event.recording {
            delegate?.mediaPlayerStartedRecording(self)
        } else {
            let path = event.filePath ?? ""
            delegate?.mediaPlayer(self, recordingStoppedAtPath: path)
        }
    }
}

// MARK: - Event Handlers

private func HandleMediaInstanceStateChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    var newState: VLCMediaPlayerState = .stopped

    switch event.type {
    case libvlc_MediaPlayerPlaying:
        newState = .playing
    case libvlc_MediaPlayerPaused:
        newState = .paused
    case libvlc_MediaPlayerStopped:
        newState = .stopped
    case libvlc_MediaPlayerEncounteredError:
        newState = .error
    case libvlc_MediaPlayerBuffering:
        newState = .buffering
    case libvlc_MediaPlayerOpening:
        newState = .opening
    case libvlc_MediaPlayerEndReached:
        newState = .ended
    case libvlc_MediaPlayerESAdded:
        newState = .esAdded
    default:
        return
    }

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        let notification = Notification(name: VLCMediaPlayerStateChanged, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerStateChanged(notification)
    }
}

private func HandleMediaPositionChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        let newPosition = NSNumber(value: event.u.media_player_position_changed.new_position)
        mediaPlayer.handlePositionChanged(newPosition)
    }
}

private func HandleMediaTimeChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    let newTime = NSNumber(value: event.u.media_player_time_changed.new_time)

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        mediaPlayer.handleTimeChanged(newTime)

        let notification = Notification(name: VLCMediaPlayerTimeChanged, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerTimeChanged(notification)
    }
}

private func HandleMediaPlayerMediaChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    let newMedia = VLCMedia(libVLCMediaDescriptor: event.u.media_player_media_changed.new_media)

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        mediaPlayer.handleMediaChanged(newMedia)
    }
}

private func HandleMediaTitleChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        let newTitle = NSNumber(value: event.u.media_player_title_changed.new_title)
        mediaPlayer.handleTitleChanged(newTitle)

        let notification = Notification(name: VLCMediaPlayerTitleChanged, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerTitleChanged(notification)
    }
}

private func HandleMediaChapterChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        let newChapter = NSNumber(value: event.u.media_player_chapter_changed.new_chapter)
        mediaPlayer.handleChapterChanged(newChapter)

        let notification = Notification(name: VLCMediaPlayerChapterChanged, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerChapterChanged(notification)
    }
}

private func HandleMediaLoudnessChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    let loudness = VLCMediaLoudness(loudnessValue: Double(event.u.media_player_loudness_changed.momentary_loudness),
                                    date: event.u.media_player_loudness_changed.date * 1000)

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        mediaPlayer.handleLoudnessChanged(loudness)

        let notification = Notification(name: VLCMediaPlayerLoudnessChanged, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerLoudnessChanged(loudness)
    }
}

private func HandleMediaPlayerSnapshot(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    guard let psz_filename = event.u.media_player_snapshot_taken.psz_filename else { return }
    let fileName = String(cString: psz_filename)

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        mediaPlayer.handleSnapshot(fileName)

        let notification = Notification(name: VLCMediaPlayerSnapshotTaken, object: mediaPlayer)
        NotificationCenter.default.post(notification)
        mediaPlayer.delegate?.mediaPlayerSnapshot(fileName)
    }
}

private func HandleMediaPlayerRecord(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    let recording = event.u.media_player_record_changed.recording != 0
    let filePath = event.u.media_player_record_changed.file_path.map { String(cString: $0) }

    eventsHandler.handleEvent { object in
        let mediaPlayer = object as! VLCMediaPlayer
        let recordEvent = VLCMediaPlayerRecordEvent(recording: recording, filePath: filePath)
        mediaPlayer.handleRecord(recordEvent)
    }
}

// MARK: - Helper Structs

public struct VLCVideoViewpoint {
    public var yaw: Float
    public var pitch: Float
    public var roll: Float
    public var fov: Float

    fileprivate var ptr: OpaquePointer {
        var viewpoint = libvlc_video_new_viewpoint()
        viewpoint.pointee.f_yaw = yaw
        viewpoint.pointee.f_pitch = pitch
        viewpoint.pointee.f_roll = roll
        viewpoint.pointee.f_field_of_view = fov
        return viewpoint
    }

    public init(yaw: Float, pitch: Float, roll: Float, fov: Float) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
        self.fov = fov
    }
}

public struct VLCMediaPlayerRecordEvent {
    public var recording: Bool
    public var filePath: String?

    public init(recording: Bool, filePath: String?) {
        self.recording = recording
        self.filePath = filePath
    }
}
