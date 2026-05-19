import Foundation

// MARK: - Preset
extension VLCAudioEqualizer.Preset {
       @objc var name: String { _name }
       @objc var index: UInt { _index }
     private let _name: String
     private let _index: UInt
}

// MARK: - Band
extension VLCAudioEqualizer.Band {
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

// MARK: - Main equalizer
extension VLCAudioEqualizer {
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
          get { libvlc_audio_equalizer_get_preamp(self) }
          set {
              libvlc_audio_equalizer_set_preamp(self, newValue)
              applyToMediaPlayer()
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
        libvlc_audio_equalizer_get_amp_at_index(self, index)
         }
    
    private func setAmplification(_ amplification: Float, bandIndex: UInt) {
        libvlc_audio_equalizer_set_amp_at_index(self, amplification, bandIndex)
        applyToMediaPlayer()
         }
    
    private func applyToMediaPlayer() {
        // The equalizer is automatically applied when mediaPlayer is set
         }
    
    deinit {
        libvlc_audio_equalizer_release(self)
         }
}
