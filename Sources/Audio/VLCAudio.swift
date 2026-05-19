import Foundation

public extension VLCMediaPlayer {
       @objc public var audio: VLCAudio {
          if _audio == nil {
              _audio = VLCAudio(mediaPlayer: self)
             }
          return _audio!
          }
      private var _audio: VLCAudio?
}

public extension VLCAudio {
       @objc static var volumeChangedNotification: NSNotificationName {
          return NSNotificationName("VLCMediaPlayerVolumeChangedNotification")
           }
       @objc var volume: Int {
          get { return libvlc_audio_get_volume(instance) }
          set {
              let vol = max(min(newValue, 200), 0)
              libvlc_audio_set_volume(instance, vol)
              }
          }
       @objc var muted: Bool {
          get { return libvlc_audio_get_mute(instance) != 0 }
          set { libvlc_audio_set_mute(instance, newValue ? 1 : 0) }
          }
       @objc var passthrough: Bool {
          get {
              let device = libvlc_audio_output_device_get(instance)
              let result = device != nil && strcmp(device, "encoded") == 0
              free(device)
              return result
              }
          set {
              if newValue {
                  libvlc_audio_output_device_set(instance, "encoded")
                  } else {
                  libvlc_audio_output_device_set(instance, "pcm")
                  }
              }
          }
       @objc func volumeUp() {
          self.volume += 6
          }
       @objc func volumeDown() {
          self.volume -= 6
          }
      private var instance: libvlc_media_player_t {
          return libVLCMediaPlayer
          }
}
