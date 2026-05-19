import Foundation

public extension VLCMediaPlayer {
       @objc var audio: VLCAudio {
          if _audio == nil {
              _audio = VLCAudio(mediaPlayer: self)
           }
          return _audio!
         }
     private var _audio: VLCAudio?
}

public extension VLCAudio {
       @objc static var volumeChangedNotification: NSNotificationName {
          NSNotificationName("VLCMediaPlayerVolumeChangedNotification")
          }
    
       @objc var volume: Int {
          get { libvlc_audio_get_volume(self) }
          set {
              let vol = max(min(newValue, 200), 0)
              libvlc_audio_set_volume(self, vol)
              }
          }
    
       @objc var muted: Bool {
          get { libvlc_audio_get_mute(self) != 0 }
          set { libvlc_audio_set_mute(self, newValue ? 1 : 0) }
          }
    
       @objc var passthrough: Bool {
          get {
              let device = libvlc_audio_output_device_get(self, nil, nil)
              let result = device != nil && strcmp(device, "encoded") == 0
              if device != nil { free(device) }
              return result
              }
          set {
              if newValue {
                  libvlc_audio_output_device_set(self, nil, "encoded")
                  } else {
                  libvlc_audio_output_device_set(self, nil, "pcm")
                  }
              }
          }
    
       @objc func volumeUp() {
          self.volume += 6
          }
       @objc func volumeDown() {
          self.volume -= 6
          }
}
