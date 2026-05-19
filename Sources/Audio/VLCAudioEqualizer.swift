import Foundation

public extension VLCAudioEqualizer {
       @objc static var presets: [VLCAudioEqualizer.Preset] {
          let count = libvlc_audio_equalizer_get_preset_count()
          var presets: [VLCAudioEqualizer.Preset] = []
          for index in 0..<count {
              let name = libvlc_audio_equalizer_get_preset_name(index) ?? ""
              presets.append(VLCAudioEqualizer.Preset(name: name, index: index))
             }
          return presets
          }
       @objc var preAmplification: Float {
          get { return libvlc_audio_equalizer_get_preamp(equalizer) }
          set {
              libvlc_audio_equalizer_set_preamp(equalizer, newValue)
              setLibEqualizerOnLibMediaPlayer()
              }
          }
       @objc var bands: [VLCAudioEqualizer.Band] {
          let count = libvlc_audio_equalizer_get_band_count()
          var bands: [VLCAudioEqualizer.Band] = []
          for index in 0..<count {
              let freq = libvlc_audio_equalizer_get_band_frequency(index)
              bands.append(VLCAudioEqualizer.Band(equalizer: self, frequency: freq, index: index))
             }
          return bands
          }
      private func amplification(forBandIndex index: UInt) -> Float {
          return libvlc_audio_equalizer_get_amp_at_index(equalizer, index)
          }
      private func setAmplification(_ amplification: Float, bandIndex: UInt) {
          libvlc_audio_equalizer_set_amp_at_index(equalizer, amplification, bandIndex)
          setLibEqualizerOnLibMediaPlayer()
          }
      private func setLibEqualizerOnLibMediaPlayer() {
          if let player = mediaPlayer, let p_mi = player.libVLCMediaPlayer {
              libvlc_media_player_set_equalizer(p_mi, equalizer)
              }
          }
      deinit {
          libvlc_audio_equalizer_release(equalizer)
          }
}

public extension VLCAudioEqualizer.Preset {
       @objc var name: String { _name }
       @objc var index: UInt { _index }
      private let _name: String
      private let _index: UInt
}

public extension VLCAudioEqualizer.Band {
       @objc var frequency: Float { _frequency }
       @objc var index: UInt { _index }
       @objc var amplification: Float {
          get { equalizer.amplification(forBandIndex: _index) }
          set { equalizer.setAmplification(newValue, bandIndex: _index) }
          }
      private let equalizer: VLCAudioEqualizer
      private let _frequency: Float
      private let _index: UInt
}
