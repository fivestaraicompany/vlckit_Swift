//
//  VLCAudio.swift
//  VLCKit
//
//  VLCAudio - Audio control for VLC media player
//

import Foundation
import CLibVLC

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
    public var volume: Int {
        get {
            guard let playerInstance = _playerInstance else { return 0 }
            return Int(libvlc_audio_get_volume(playerInstance))
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            let clampedVolume = max(volumeMin, min(volumeMax, newValue))
            libvlc_audio_set_volume(playerInstance, Int32(clampedVolume))
        }
    }

    /// Whether audio is muted
    public var muted: Bool {
        get {
            guard let playerInstance = _playerInstance else { return false }
            return libvlc_audio_get_mute(playerInstance) != 0
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            libvlc_audio_set_mute(playerInstance, newValue ? 1 : 0)
        }
    }

    /// Whether passthrough mode is enabled
    public var passthrough: Bool {
        get {
            guard let playerInstance = _playerInstance else { return false }
            guard let deviceIdentifier = libvlc_audio_output_device_get(playerInstance) else {
                return false
            }
            let isPassthrough = strcmp(deviceIdentifier, "encoded") == 0
            libvlc_free(UnsafeMutableRawPointer(mutating: deviceIdentifier))
            return isPassthrough
        }
        set {
            guard let playerInstance = _playerInstance else { return }
            if newValue {
                libvlc_audio_output_device_set(playerInstance, nil, "encoded")
            } else {
                libvlc_audio_output_device_set(playerInstance, nil, "pcm")
            }
        }
    }

    /// Increase volume
    public func volumeUp() {
        volume = min(volumeMax, volume + volumeStep)
    }

    /// Decrease volume
    public func volumeDown() {
        volume = max(volumeMin, volume - volumeStep)
    }

    /// Initialize with a media player instance
    public init?(mediaPlayerInstance playerInstance: OpaquePointer?) {
        guard let playerInstance = playerInstance else {
            return nil
        }
        self._playerInstance = playerInstance
        libvlc_media_player_retain(playerInstance)
        super.init()
    }

    deinit {
        if let playerInstance = _playerInstance {
            libvlc_media_player_release(playerInstance)
        }
    }
}
