import Foundation

// MARK: - Repeat mode
extension VLCRepeatMode {
     static let doNotRepeat: VLCRepeatMode = VLCRepeatMode(rawValue: VLCDoNotRepeat.rawValue)
     static let repeatCurrentItem: VLCRepeatMode = VLCRepeatMode(rawValue: VLCRepeatCurrentItem.rawValue)
     static let repeatAllItems: VLCRepeatMode = VLCRepeatMode(rawValue: VLCRepeatAllItems.rawValue)
}

// MARK: - Notifications
public extension VLCMediaListPlayer {
    static var finishedPlaybackNotification: NSNotificationName {
        NSNotificationName("VLCMediaListPlayerFinishedPlayback")
      }
    static var nextMediaNotification: NSNotificationName {
        NSNotificationName("VLCMediaListPlayerNextMedia")
      }
    static var stoppedNotification: NSNotificationName {
        NSNotificationName("VLCMediaListPlayerStopped")
      }
}

// MARK: - Playback
public extension VLCMediaListPlayer {
     @objc func play() {
        libvlc_media_list_player_play(self)
      }
     @objc func pause() {
        libvlc_media_list_player_pause(self, 1)
      }
     @objc func stop() {
        libvlc_media_list_player_stop(self)
      }
     @objc var hasNext: Bool {
        libvlc_media_list_player_next(self) == 0
      }
     @objc var hasPrevious: Bool {
        libvlc_media_list_player_previous(self) == 0
      }
     @objc func play(at index: Int) {
        libvlc_media_list_player_play_item_at_index(self, index)
      }
     @objc func play(media: VLCMedia) {
        libvlc_media_list_player_play_item(self, media.libVLCMediaDescriptor)
      }
     @objc var repeatMode: VLCRepeatMode {
        get {
            let mode = libvlc_media_list_player_get_playback_mode(self)
            switch mode {
            case libvlc_playback_mode_loop: return .repeatAllItems
            case libvlc_playback_mode_repeat: return .repeatCurrentItem
            default: return .doNotRepeat
            }
          }
        set {
            let mode: Int = switch newValue {
            case .repeatAllItems: libvlc_playback_mode_loop
            case .doNotRepeat: libvlc_playback_mode_default
            case .repeatCurrentItem: libvlc_playback_mode_repeat
            }
            libvlc_media_list_player_set_playback_mode(self, mode)
          }
       }
}
