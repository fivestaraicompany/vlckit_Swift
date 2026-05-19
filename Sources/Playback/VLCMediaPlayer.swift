import Foundation

// MARK: - Notification names
public extension VLCMediaPlayer {
    static var timeChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerTimeChangedNotification")
    }
    static var stateChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerStateChangedNotification")
    }
    static var titleSelectionChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerTitleSelectionChangedNotification")
    }
    static var titleListChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerTitleListChangedNotification")
    }
    static var chapterChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerChapterChangedNotification")
    }
    static var snapshotTakenNotification: NSNotificationName {
        NSNotificationName("VLCMediaPlayerSnapshotTakenNotification")
    }
}

// MARK: - State to string
public extension VLCMediaPlayer {
    static func stateToString(_ state: VLCMediaPlayerState) -> String {
        let names: [String] = [
            "VLCMediaPlayerStateStopped",
            "VLCMediaPlayerStateStopping",
            "VLCMediaPlayerStateOpening",
            "VLCMediaPlayerStateBuffering",
            "VLCMediaPlayerStateError",
            "VLCMediaPlayerStatePlaying",
            "VLCMediaPlayerStatePaused",
        ]
        let idx = min(Int(state.rawValue), names.count - 1)
        return names[idx]
    }
}

// MARK: - Convenience properties
public extension VLCMediaPlayer {
    @objc var playing: Bool {
        self.isPlaying
    }
    @objc var seekable: Bool {
        self.isSeekable
    }
    
    @objc var canPause: Bool {
        self.canPause
    }
    
    @objc var time: VLCTime {
        get {
            let ms = libvlc_media_player_get_time(self)
            return VLCTime.timeWithNumber(ms)
        }
        set {
            libvlc_media_player_set_time(self, newValue.intValue)
        }
    }
    
    @objc var position: Double {
        get {
            libvlc_media_player_get_position(self)
        }
        set {
            libvlc_media_player_set_position(self, newValue)
        }
    }
}

// MARK: - Deinterlace
public extension VLCMediaPlayer {
    @objc var deinterlace: VLCDeinterlace {
        let raw = libvlc_video_get_deinterlace(self)
        switch raw {
        case libvlc_deinterlace_on: return .on
        case libvlc_deinterlace_off: return .off
        default: return .auto
        }
    }
    
    @objc var enableDeinterlace: Bool {
        get {
            let mode = libvlc_video_get_deinterlace(self)
            return mode != libvlc_deinterlace_off
        }
        set {
            let mode = newValue ? libvlc_deinterlace_on : libvlc_deinterlace_off
            libvlc_video_set_deinterlace(self, mode)
        }
    }
}

// MARK: - Audio device control
public extension VLCMediaPlayer {
    @objc var audioDevices: [String] {
        let count = libvlc_audio_output_device_count(self, nil)
        guard count > 0 else { return [] }
        
        var names: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>? = nil
        let devicesList = libvlc_audio_output_device_list_get(self, &names)
        
        defer {
            if let list = devicesList {
                for i in 0..<Int(count) {
                    free(names?[i])
                }
                free(list)
                free(names)
            }
        }
        
        guard let devicesList = devicesList, let names = names else { return [] }
        
        var devices: [String] = []
        for i in 0..<Int(count) {
            if let device = devicesList[i]?.pointee {
                devices.append(String(cString: device))
            }
        }
        return devices
    }
    
    @objc var audioDevice: String? {
        let result = libvlc_audio_output_device_get(self, nil, nil)
        return result != nil ? String(cString: result!) : nil
    }
    
    @objc func setAudioDevice(_ device: String?) {
        let cDevice = device.map { String(cString: $0.utf8) } ?? ""
        libvlc_audio_output_device_set(self, nil, cDevice)
    }
    
    @objc var audioDeviceDescription: String? {
        return audioDevice
    }
    
    @objc var audioDevicePairs: [String] {
        var pairs: [String] = []
        let count = libvlc_audio_output_device_count(self, nil)
        guard count > 0 else { return pairs }
        
        var names: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>? = nil
        let deviceList = libvlc_audio_output_device_list_get(self, &names)
        defer {
            if let list = deviceList {
                for i in 0..<Int(count) {
                    free(names?[i])
                }
                free(list)
                free(names)
            }
        }
        
        guard let deviceList = deviceList, let names = names else { return pairs }
        
        for i in 0..<Int(count) {
            if let deviceName = deviceList[i] {
                let output = String(cString: deviceName.pointee)
                if let outputModule = deviceList[i + 1]?.pointee {
                    let module = String(cString: outputModule)
                    pairs.append("\(output)|\(module)")
                } else {
                    pairs.append(output)
                }
            }
        }
        return pairs
    }
    
    @objc var audioDevicePair: String? {
        return audioDevice
    }
    
    @objc func setAudioDevicePair(_ device: String?) {
        setAudioDevice(device)
    }
}

// MARK: - 3D / Viewpoint
public extension VLCMediaPlayer {
    @objc func updateViewpoint(yaw: Float, pitch: Float, roll: Float, fov: Float, absolute: Bool) -> Bool {
        libvlc_media_player_update_viewpoint(self, yaw, pitch, roll, fov, absolute ? 1 : 0) != 0
    }
}

// MARK: - Playback control
public extension VLCMediaPlayer {
    @objc func playNext() {
        libvlc_media_player_next_frame(self)
    }
    
    @objc func playPrevious() {
        libvlc_media_player_previous_frame(self)
    }
}

// MARK: - Jump controls
public extension VLCMediaPlayer {
    @objc func shortJumpForward() {
        let currentTime = libvlc_media_player_get_time(self)
        libvlc_media_player_set_time(self, currentTime + 30000)
    }
    
    @objc func shortJumpBackward() {
        let currentTime = libvlc_media_player_get_time(self)
        libvlc_media_player_set_time(self, currentTime - 30000)
    }
    
    @objc func longJumpForward() {
        let currentTime = libvlc_media_player_get_time(self)
        libvlc_media_player_set_time(self, currentTime + 300000)
    }
    
    @objc func longJumpBackward() {
        let currentTime = libvlc_media_player_get_time(self)
        libvlc_media_player_set_time(self, currentTime - 300000)
    }
}

// MARK: - Media
public extension VLCMediaPlayer {
    @objc func set(media: VLCMedia?) {
        if let m = media {
            libvlc_media_player_set_media(self, m.libVLCMediaDescriptor)
        } else {
            libvlc_media_player_set_media(self, nil)
        }
    }
}

// MARK: - Snapshot
public extension VLCMediaPlayer {
    @objc func snapshot(at path: String, index: UInt) -> Bool {
        libvlc_media_player_take_snapshot(self, index, path, 0) == 0
    }
}

// MARK: - Renderer
public extension VLCMediaPlayer {
    @objc func set(rendererItem item: VLCRendererItem?) -> Bool {
        #if !TARGET_OS_TV
        return libvlc_media_player_set_renderer_instance(self, item?.libVLCRendererItem()) != nil
        #else
        return false
        #endif
    }
}

// MARK: - Track selection
public extension VLCMediaPlayer {
    @objc func select(trackAtIndex index: Int, type: VLCMedia.TrackType) {
        let trackType: Int = switch type {
        case .audio: libvlc_track_audio
        case .video: libvlc_track_video
        case .text: libvlc_track_text
        case .unknown: libvlc_track_video   // fallback
        }
        
        let tracklist = libvlc_media_player_get_tracklist(self, trackType, 1)
        guard tracklist != nil else { return }
        
        let count = libvlc_media_tracklist_count(tracklist)
        if index >= 0 && index < Int(count) {
            let track = libvlc_media_tracklist_at(tracklist, UInt(index))
            if track != nil {
                libvlc_media_player_select_track(self, track)
            }
        }
        libvlc_media_tracklist_delete(tracklist)
    }
    
    @objc func deselectAllAudioTracks() {
        libvlc_media_player_unselect_track_type(self, libvlc_track_audio)
    }
    
    @objc func deselectAllVideoTracks() {
        libvlc_media_player_unselect_track_type(self, libvlc_track_video)
    }
    
    @objc func select(textTracks tracks: [VLCMediaPlayerTrack]) {
        guard !tracks.isEmpty else {
            deselectAllTextTracks()
            return
        }
        let ids = tracks.compactMap { $0.trackId }
        let idsString = ids.joined(separator: ",")
        libvlc_media_player_select_tracks_by_ids(self, libvlc_track_text, idsString)
    }
    
    @objc func deselectAllTextTracks() {
        libvlc_media_player_unselect_track_type(self, libvlc_track_text)
    }
}

// MARK: - Playback state
public extension VLCMediaPlayer {
    @objc var playbackState: VLCMediaPlayerState {
        self.state
    }
}

// MARK: - Chapter / Title / Navigation
public extension VLCMediaPlayer {
    @objc var currentTitleIndex: Int {
        libvlc_media_player_get_title(self)
    }
    
    @objc var currentChapterIndex: Int {
        libvlc_media_player_get_chapter(self)
    }
    
    @objc func setCurrentTitle(_ titleIndex: Int) {
        libvlc_media_player_set_title(self, titleIndex, 0)
    }
    
    @objc func setCurrentChapter(_ chapterIndex: Int) {
        libvlc_media_player_set_chapter(self, chapterIndex)
    }
    
    @objc var titleCount: Int {
        libvlc_media_player_get_title_count(self)
    }
    
    @objc func chapterCount(forTitle titleIndex: Int) -> Int {
        libvlc_media_player_get_chapter_count(self, titleIndex)
    }
}

// MARK: - Volume
public extension VLCMediaPlayer {
    @objc var volume: Int {
        get {
            libvlc_audio_get_volume(self)
        }
        set {
            libvlc_audio_set_volume(self, newValue)
        }
    }
    
    @objc var isMuted: Bool {
        get {
            libvlc_audio_get_mute(self) != 0
        }
        set {
            libvlc_audio_set_mute(self, newValue ? 1 : 0)
        }
    }
}

// MARK: - Recording
public extension VLCMediaPlayer {
    @objc func startRecording(at path: String) {
        // Recording API would need Objective-C implementation
        // This is a stub
    }
    
    @objc func stopRecording() {
        // Recording stop API would need Objective-C implementation
    }
}
