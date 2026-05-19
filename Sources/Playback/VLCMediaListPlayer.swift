import Foundation

public extension VLCMediaListPlayer {
       @objc public static var finishedPlaybackNotification: NSNotificationName {
           return NSNotificationName("VLCMediaListPlayerFinishedPlayback")
           }
      @objc public static var nextMediaNotification: NSNotificationName {
          return NSNotificationName("VLCMediaListPlayerNextMedia")
          }
      @objc public static var stoppedNotification: NSNotificationName {
          return NSNotificationName("VLCMediaListPlayerStopped")
          }
}

public extension VLCMediaListPlayer {
      @objc public func play() {
          libvlc_media_list_player_play(instance)
          }
      @objc public func pause() {
          libvlc_media_list_player_set_pause(instance, 1)
          }
      @objc public func stop() {
          libvlc_media_list_player_stop_async(instance)
          }
      @objc public var hasNext: Bool {
          return libvlc_media_list_player_next(instance) == 0
          }
      @objc public var hasPrevious: Bool {
          return libvlc_media_list_player_previous(instance) == 0
          }
      @objc public func play(at index: Int) {
          libvlc_media_list_player_play_item_at_index(instance, index)
          }
      @objc public func play(media: VLCMedia) {
          libvlc_media_list_player_play_item(instance, media.libVLCMediaDescriptor)
          }
      @objc public var repeatMode: VLCRepeatMode {
          get {
              let mode = libvlc_media_list_player_get_playback_mode(instance)
              switch mode {
              case libvlc_playback_mode_loop: return .repeatAllItems
              case libvlc_playback_mode_repeat: return .repeatCurrentItem
              default: return .doNotRepeat
              }
          }
          set {
              let mode: libvlc_playback_mode_t = switch newValue {
              case .repeatAllItems: libvlc_playback_mode_loop
              case .doNotRepeat: libvlc_playback_mode_default
              case .repeatCurrentItem: libvlc_playback_mode_repeat
              }
              libvlc_media_list_player_set_playback_mode(instance, mode)
          }
      }
}
