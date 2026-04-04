//
//  VLCTranscoder.swift
//  VLCKit
//
//  VLCTranscoder - Transcoder for VLC
//

import Foundation

/**
 Protocol for transcoder delegate
 */
public protocol VLCTranscoderDelegate: AnyObject {
    func transcode(_ transcoder: VLCTranscoder, finishedSucessfully success: Bool)
}

/**
 VLCTranscoder - Transcoder for VLC
 */
public class VLCTranscoder: NSObject {

    public weak var delegate: (any VLCTranscoderDelegate)? = nil

    private var _playerInstance: OpaquePointer? = nil
    private var _libVLCTranscoderQueue: DispatchQueue?
    private var _eventsHandler: VLCEventsHandler?

         /**
     Create a new transcoder
           */
    public override init() {
          _libVLCTranscoderQueue = DispatchQueue(label: "libVLCTranscoderQueue", attributes: .concurrent)
        super.init()
          }

    public func reencodeAndMuxSRTFile(srtPath: String, toMP4File mp4Path: String, outputPath outPath: String) -> Bool {
        let media = libvlc_media_new_path(VLCLibrary.sharedLibrary.instance, mp4Path)
        guard let p_media = media else {
            NSAssert(false, "p_media wasn't allocated")
            return false
           }

        let transcodingOptions = ":sout=#transcode{venc={module=avcodec{codec=h264_videotoolbox}, vcodec=h264},venc={module=vpx{quality-mode=2},vcodec=VP80},samplerate=44100,soverlay}:file{dst='\(outPath)',mux=mkv}"
        libvlc_media_add_option(p_media, "--sub-file=\(srtPath)")
        libvlc_media_add_option(p_media, transcodingOptions)

         _playerInstance = libvlc_media_player_new_from_media(p_media)
        guard let playerInstance = _playerInstance else {
            NSAssert(false, "_p_mp wasn't allocated")
            return false
           }

        registerObserversForMux(withPlayer: playerInstance)

        let canPlay = libvlc_media_player_play(playerInstance) == 0
        if !canPlay {
            NSAssert(false, "playback failed")
            unregisterObserversForMux(withPlayer: playerInstance)
            return false
           }

        return canPlay
          }

    private func registerObserversForMux(withPlayer player: OpaquePointer) {
        guard let em = libvlc_media_player_event_manager(player) else { return }

         _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)

         _libVLCTranscoderQueue?.sync {
            libvlc_event_attach(em, libvlc_MediaPlayerPaused, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
            libvlc_event_attach(em, libvlc_MediaPlayerStopped, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
            libvlc_event_attach(em, libvlc_MediaPlayerEncounteredError, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
             }
          }

    private func unregisterObserversForMux(withPlayer player: OpaquePointer) {
        guard let em = libvlc_media_player_event_manager(player) else { return }

         _libVLCTranscoderQueue?.sync {
            libvlc_event_detach(em, libvlc_MediaPlayerStopped, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
            libvlc_event_detach(em, libvlc_MediaPlayerPaused, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
            libvlc_event_detach(em, libvlc_MediaPlayerEncounteredError, HandleMuxMediaInstanceStateChanged, Unmanaged.passRetained(_eventsHandler!).toOpaque())
             }

        CFBridgingRelease(Unmanaged.passRetained(self) as CFTypeRef)
          }

    private func mediaPlayerStateChangeForMux(_ newState: NSNumber) {
        guard let playerInstance = _playerInstance else { return }

        unregisterObserversForMux(withPlayer: playerInstance)
        libvlc_media_player_stop(playerInstance)

        if delegate != nil && delegate?.responds(to: #selector(transcode(_:finishedSucessfully:))) == true {
            let success = newState != NSNumber(value: VLCMediaPlayerState.error.rawValue)
            delegate?.transcode(self, finishedSucessfully: success)
             }
          }

    deinit {
        if let playerInstance = _playerInstance {
            libvlc_media_player_release(playerInstance)
             }
          }
}

// MARK: - Event Handlers

private func HandleMuxMediaInstanceStateChanged(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    var newState: VLCMediaPlayerState = .error

    switch event.type {
    case libvlc_MediaPlayerPaused:
        newState = .paused
    case libvlc_MediaPlayerStopped:
        newState = .stopped
    default:
        newState = .error
    }

    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let transcoder = object as! VLCTranscoder
        transcoder.mediaPlayerStateChangeForMux(NSNumber(value: newState.rawValue))
       }
}
