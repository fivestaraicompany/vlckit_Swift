//
//  VLCAudio.swift
//  VLCKit
//
//  VLCAudio - Audio control for VLC media player
//

import Foundation

/**
 Notification name for volume changes
 */
public let VLCMediaPlayerVolumeChanged = "VLCMediaPlayerVolumeChanged"

/**
 Basic class to control audio output
 */
public final class VLCAudio: NSObject {

    private var _playerInstance: OpaquePointer?

    private let volumeMax = 200
    private let volumeMin = 0
    private let volumeStep = 6

      /// The current audio volume (0-200)
    public var volume: Int = 0 {
        didSet {
            let clampedVolume = max(volumeMin, min(volumeMax, volume))
            libvlc_audio_set_volume(_playerInstance, clampedVolume)
         }
     }

      /// Whether audio is muted
    public var muted: Bool {
        get {
            return libvlc_audio_get_mute(_playerInstance) != 0
         }
        set {
            libvlc_audio_set_mute(_playerInstance, newValue ? 1 : 0)
         }
     }

      /// Whether passthrough mode is enabled
    public var passthrough: Bool = false {
        get {
            guard let deviceIdentifier = libvlc_audio_output_device_get(_playerInstance) else {
                return false
             }
            let isPassthrough = strcmp(deviceIdentifier, "encoded") == 0
            libvlc_free(deviceIdentifier)
            return isPassthrough
         }
        set {
            if newValue {
                libvlc_audio_output_device_set(_playerInstance, nil, "encoded")
             } else {
                libvlc_audio_output_device_set(_playerInstance, nil, "pcm")
             }
         }
     }

      /// Increase volume
    public func volumeUp() {
        var newVolume = volume + volumeStep
        newVolume = min(volumeMax, max(volumeMin, newVolume))
        volume = newVolume
      }

      /// Decrease volume
    public func volumeDown() {
        var newVolume = volume - volumeStep
        newVolume = min(volumeMax, max(volumeMin, newVolume))
        volume = newVolume
      }

      /// Initialize with a media player instance
    public init?(mediaPlayerInstance playerInstance: OpaquePointer?) {
        self._playerInstance = playerInstance
        guard let playerInstance = playerInstance else {
            return nil
         }
        libvlc_media_player_retain(playerInstance)
        super.init()
      }

      /// Deinitialize
    deinit {
        guard let playerInstance = _playerInstance else { return }
        libvlc_media_player_release(playerInstance)
      }
}
