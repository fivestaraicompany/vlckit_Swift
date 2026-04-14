//
//  VLCAudioEqualizer.swift
//  VLCKit
//
//  VLCAudioEqualizer - Audio equalizer for VLC
//

import Foundation
import CLibVLC

/**
 VLCAudioEqualizerBand - Represents a single equalizer band
 */
public class VLCAudioEqualizerBand: NSObject {
    public var index: UInt32 = 0
    public var frequency: Float = 0.0
    public var amplification: Float = 0.0

    public init(index: UInt32, frequency: Float, amplification: Float = 0.0) {
        self.index = index
        self.frequency = frequency
        self.amplification = amplification
        super.init()
    }
}

/**
 VLCAudioEqualizer - Audio equalizer for VLC
 */
public class VLCAudioEqualizer: NSObject {

    private var _equalizer: OpaquePointer?

    public var preAmplification: Float = 0.0
    public var bands: [VLCAudioEqualizerBand] = []
    public weak var mediaPlayer: VLCMediaPlayer?
    public var momentaryLoudness: VLCMediaLoudness?

    public override init() {
        super.init()
        let bandCount = libvlc_audio_equalizer_get_band_count()
        for i: UInt32 in 0..<bandCount {
            let freq = libvlc_audio_equalizer_get_band_frequency(i)
            bands.append(VLCAudioEqualizerBand(index: i, frequency: freq))
        }
    }

    public init(presetIndex: UInt32) {
        super.init()
        _equalizer = libvlc_audio_equalizer_new_from_preset(presetIndex)
    }

    deinit {
        if let eq = _equalizer {
            libvlc_audio_equalizer_release(eq)
        }
    }
}
