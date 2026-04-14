//
//  VLCTranscoder.swift
//  VLCKit
//
//  VLCTranscoder - Transcoder for VLC
//

import Foundation
import CLibVLC

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

    public weak var delegate: (any VLCTranscoderDelegate)?

    private var _playerInstance: OpaquePointer?
    private var _eventsHandler: VLCEventsHandler?

    public override init() {
        super.init()
    }

    public func reencodeAndMuxSRTFile(srtPath: String, toMP4File mp4Path: String, outputPath outPath: String) -> Bool {
        let media = libvlc_media_new_path(VLCLibrary.sharedLibrary.instance, mp4Path)
        guard let p_media = media else {
            return false
        }

        let transcodingOptions = ":sout=#transcode{venc={module=avcodec{codec=h264_videotoolbox}, vcodec=h264},venc={module=vpx{quality-mode=2},vcodec=VP80},samplerate=44100,soverlay}:file{dst='\(outPath)',mux=mkv}"
        libvlc_media_add_option(p_media, "--sub-file=\(srtPath)")
        libvlc_media_add_option(p_media, transcodingOptions)

        _playerInstance = libvlc_media_player_new_from_media(p_media)
        libvlc_media_release(p_media)

        guard let playerInstance = _playerInstance else {
            return false
        }

        let canPlay = libvlc_media_player_play(playerInstance) == 0
        if !canPlay {
            return false
        }

        return canPlay
    }

    deinit {
        if let playerInstance = _playerInstance {
            libvlc_media_player_stop(playerInstance)
            libvlc_media_player_release(playerInstance)
        }
    }
}
