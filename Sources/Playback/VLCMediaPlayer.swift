import Foundation

// MARK: - Notification extensions
public extension VLCMediaPlayer {
    static var timeChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerTimeChangedNotification")
         }
    static var stateChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerStateChangedNotification")
         }
    static var titleSelectionChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerTitleSelectionChangedNotification")
         }
    static var titleListChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerTitleListChangedNotification")
         }
    static var chapterChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerChapterChangedNotification")
         }
    static var snapshotTakenNotification: NSNotificationName {
        return NSNotificationName("VLCMediaPlayerSnapshotTakenNotification")
         }
}

// MARK: - State string conversion
public extension VLCMediaPlayer {
    static func stateToString(_ state: VLCMediaPlayerState) -> String {
        let stateToStrings: [String] = [
             "VLCMediaPlayerStateStopped",
             "VLCMediaPlayerStateStopping",
             "VLCMediaPlayerStateOpening",
             "VLCMediaPlayerStateBuffering",
             "VLCMediaPlayerStateError",
             "VLCMediaPlayerStatePlaying",
             "VLCMediaPlayerStatePaused",
            ]
        return stateToStrings[Int(state.rawValue)] ?? "Unknown"
         }
}

// MARK: - Convenience properties
public extension VLCMediaPlayer {
     @objc public var playing: Bool {
          return isPlaying
         }
     @objc public var seekable: Bool {
          return isSeekable
         }
     @objc public var canPause: Bool {
          return self.canPause
         }
      @objc public var time: VLCTime {
          get {
              let ms = libvlc_media_player_get_time(libVLCMediaPlayer)
              return VLCTime.timeWithNumber(ms)
             }
          set {
              libvlc_media_player_set_time(libVLCMediaPlayer, newValue.intValue)
             }
         }
      @objc public var position: Double {
          get {
              return libvlc_media_player_get_position(libVLCMediaPlayer)
             }
          set {
              libvlc_media_player_set_position(libVLCMediaPlayer, newValue)
             }
         }
}

// MARK: - Deinterlace
public extension VLCMediaPlayer {
      @objc public var deinterlace: VLCDeinterlace {
          return libvlc_media_player_get_deinterlace(libVLCMediaPlayer)
         }
      @objc public var enableDeinterlace: Bool {
          get {
              return libvlc_media_player_get_deinterlace(libVLCMediaPlayer) != .off
             }
          set {
              libvlc_media_player_set_deinterlace(libVLCMediaPlayer, newValue ? .on : .off)
             }
         }
}

// MARK: - Audio device control
public extension VLCMediaPlayer {
      @objc public var audioDevices: [String] {
          var devices: [String] = []
          let count = libvlc_audio_output_device_count(libVLCMediaPlayer, nil)
          if count > 0 {
              var deviceNames: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>? = nil
              let deviceList = libvlc_audio_output_device_list_get(libVLCMediaPlayer, &deviceNames)
              if let deviceList = deviceList {
                  for i in 0..<count {
                      if let name = deviceList[i]?.pointee {
                          devices.append(String(cString: name))
                         }
                      free(deviceNames![i])
                      }
                  free(deviceList)
                  free(deviceNames)
                 }
             }
          return devices
         }
      @objc public var audioDevice: String? {
          return libvlc_audio_output_device_get(libVLCMediaPlayer, nil)
          }
      @objc public func setAudioDevice(_ device: String?) {
          libvlc_audio_output_device_set(libVLCMediaPlayer, nil, device ?? "")
         }
      @objc public var audioDeviceDescription: String? {
          return libvlc_audio_output_device_get(libVLCMediaPlayer, nil)
         }
      @objc public var audioDevicePairs: [String] {
          var pairs: [String] = []
          let count = libvlc_audio_output_device_count(libVLCMediaPlayer, nil)
          if count > 0 {
              var deviceNames: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>? = nil
              let deviceList = libvlc_audio_output_device_list_get(libVLCMediaPlayer, &deviceNames)
              if let deviceList = deviceList {
                  for i in 0..<count {
                      if let device = deviceList[i]?.pointee,
                         let name = deviceNames?[i]?.pointee {
                          pairs.append("\(name):\(device)")
                         }
                      free(deviceNames![i])
                      }
                  free(deviceList)
                  free(deviceNames)
                 }
             }
          return pairs
         }
      @objc public var audioDevicePair: String? {
          return libvlc_audio_output_device_get(libVLCMediaPlayer, nil)
         }
      @objc public func setAudioDevicePair(_ device: String?) {
          libvlc_audio_output_device_set(libVLCMediaPlayer, nil, device ?? "")
         }
}

// MARK: - Filters and Equalizer
public extension VLCMediaPlayer {
      @objc public var adjustFilter: VLCAdjustFilter {
          return VLCAdjustFilter(mediaPlayer: self)
         }
      @objc public var equalizer: VLCAudioEqualizer? {
          return _equalizer
         }
      @objc public func set(equalizer: VLCAudioEqualizer?) {
          _equalizer = equalizer
          equalizer?.setMediaPlayer(self)
         }
      private var _equalizer: VLCAudioEqualizer?
}

// MARK: - Playback control
public extension VLCMediaPlayer {
      @objc public func playNext() {
          libvlc_media_player_next_frame(libVLCMediaPlayer)
         }
      @objc public func playPrevious() {
          libvlc_media_player_previous_frame(libVLCMediaPlayer)
         }
}

// MARK: - Jump controls
public extension VLCMediaPlayer {
      @objc public func shortJumpForward() {
          let currentTime = libvlc_media_player_get_time(libVLCMediaPlayer)
          libvlc_media_player_set_time(libVLCMediaPlayer, currentTime + 30000)
         }
      @objc public func shortJumpBackward() {
          let currentTime = libvlc_media_player_get_time(libVLCMediaPlayer)
          libvlc_media_player_set_time(libVLCMediaPlayer, currentTime - 30000)
         }
      @objc public func longJumpForward() {
          let currentTime = libvlc_media_player_get_time(libVLCMediaPlayer)
          libvlc_media_player_set_time(libVLCMediaPlayer, currentTime + 300000)
         }
      @objc public func longJumpBackward() {
          let currentTime = libvlc_media_player_get_time(libVLCMediaPlayer)
          libvlc_media_player_set_time(libVLCMediaPlayer, currentTime - 300000)
         }
}

// MARK: - Media
public extension VLCMediaPlayer {
      @objc public func set(media: VLCMedia?) {
          _media = media
          if let m = media {
              libvlc_media_player_set_media(libVLCMediaPlayer, m.libVLCMediaDescriptor)
             } else {
              libvlc_media_player_set_media(libVLCMediaPlayer, nil)
             }
         }
      private var _media: VLCMedia?
}

// MARK: - Snapshot
public extension VLCMediaPlayer {
      @objc public func snapshot(at path: String, index: UInt) -> Bool {
          return libvlc_media_player_take_snapshot(libVLCMediaPlayer, index, path, 0) == 0
         }
}

// MARK: - Renderer
public extension VLCMediaPlayer {
      @objc public func set(rendererItem item: VLCRendererItem?) -> Bool {
          return libvlc_media_player_set_renderer_instance(libVLCMediaPlayer, item?.libVLCRendererItem()) != nil
         }
}

// MARK: - Track selection
public extension VLCMediaPlayer {
      @objc public func select(trackAtIndex index: Int, type: VLCMedia.TrackType) {
          libvlc_media_player_set_time(libVLCMediaPlayer, 0)
         }
}

// MARK: - Playback state
public extension VLCMediaPlayer {
      @objc public var playbackState: VLCMediaPlayerState {
          return state
         }
}
