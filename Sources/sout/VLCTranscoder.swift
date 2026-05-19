import Foundation

// MARK: - Transcoder delegate proxy
public final class VLCTranscoderDelegateProxy: NSObject, VLCTranscoderDelegate {
    private let handler: (VLCTranscoder, Bool) -> Void
    
    init(handler: @escaping (VLCTranscoder, Bool) -> Void) {
        self.handler = handler
    }
    
    public func transcode(_ transcoder: VLCTranscoder, finishedSucessfully success: Bool) {
        handler(transcoder, success)
    }
}

// MARK: - Transcoder
public extension VLCTranscoder {
       @objc var delegate: VLCTranscoderDelegate? {
           get { _delegateProxy != nil ? _delegateProxy : nil }
           set {
               if let new = newValue {
                   if _delegateProxy?.handler == nil {
                       _delegateProxy = VLCTranscoderDelegateProxy { transcoder, success in
                           if let typed = new as? VLCTranscoderDelegate {
                               typed.transcode(transcoder, finishedSucessfully: success)
                           }
                       }
                   }
               } else {
                   _delegateProxy = nil
               }
           }
       }
      private var _delegateProxy: VLCTranscoderDelegateProxy?
      
       @objc func reencodeAndMuxSRTFile(_ srtPath: String, toMP4File mp4Path: String, outputPath outPath: String) -> Bool {
           let p_media = libvlc_media_new_path(mp4Path)
           guard p_media != nil else {
               VKLog("p_media wasn't allocated")
               return false
           }
           let transcodingOptions = ":sout=#transcode{venc={module=avcodec{codec=h264_videotoolbox}, vcodec=h264},samplerate=44100,soverlay}:file{dst='\(outPath)',mux=mkv}"
           libvlc_media_add_option(p_media, ("--sub-file=\(srtPath)" as NSString).utf8String!)
           libvlc_media_add_option(p_media, (transcodingOptions as NSString).utf8String!)
             _p_mp = libvlc_media_player_new_from_media(VLCLibrary.shared.instance, p_media)
           guard _p_mp != nil else {
               VKLog("_p_mp wasn't allocated")
               libvlc_media_release(p_media)
               return false
           }
           let canPlay = libvlc_media_player_play(_p_mp!) == 0
           if !canPlay {
               VKLog("playback failed")
               libvlc_media_player_release(_p_mp!)
                _p_mp = nil
               libvlc_media_release(p_media)
               return false
           }
           return canPlay
       }
      
      private var _p_mp: libvlc_media_player_t?
      
      deinit {
           _p_mp.map { libvlc_media_player_release($0) }
       }
}
