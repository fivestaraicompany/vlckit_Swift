//
//  VLCStreamSession.swift
//  VLCKit
//
//  VLCStreamSession - Stream session for VLC
//

import Foundation

/**
 VLCStreamSession - Stream session for VLC
 */
public class VLCStreamSession: VLCMediaPlayer {

    public private(set) var isComplete: Bool = false
    public private(set) var reattemptedConnections: UInt = 0

    private var _streamOutput: VLCStreamOutput?

     /**
     Create a new stream session
      */
    public override init() {
        super.init()
        addObserver(self, forKeyPath: "state", options: [.new], context: nil)
      }

    deinit {
        removeObserver(self, forKeyPath: "state")
      }

    public static func streamSession() -> VLCStreamSession {
        return VLCStreamSession()
      }

    public override var media: VLCMedia? {
        get { return super.media }
        set {
            guard let newValue = newValue else {
                super.media = nil
                return
             }

            let libvlcArgs = _streamOutput.map { "#duplicate{dst=display,dst=\"\($0.representedLibVLCOptions())\"}" }
            ?? $0.representedLibVLCOptions()

            if let args = libvlcArgs {
                let mediaWithSout = VLCMedia(media: newValue, andLibVLCOptions: ["sout": args])
                super.media = mediaWithSout
              } else {
                super.media = newValue
              }
         }
      }

    public var streamOutput: VLCStreamOutput? {
        get { return _streamOutput }
        set { _streamOutput = newValue }
      }

    public func startStreaming() {
        isComplete = false
        play()
      }

    public func stopStreaming() {
        isComplete = true
        stop()
      }

    public override func play() {
        let libvlcArgs = drawable.map { "#duplicate{dst=display,dst=\"\(_streamOutput?.representedLibVLCOptions() ?? "")\"}" }
        ?? _streamOutput?.representedLibVLCOptions()

        if let args = libvlcArgs {
            let mediaWithSout = VLCMedia(media: media ?? VLCMedia(), andLibVLCOptions: ["sout": args])
            super.media = mediaWithSout
          }

        super.play()
      }

    public override var description: String {
        if isComplete {
            return "Done."
          }

        if state == .error {
            return "Error while Converting. Open Console.app to diagnose."
          }

        return "Converting..."
      }

    public var encounteredError: Bool {
        return state == .error
      }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "state" {
            if ((position == 1.0 || state == .ended || (state == .stopped && media != nil)) || encounteredError) && media?.subitems?.count == 0 {
                isComplete = true
                return
             }

            if reattemptedConnections > 4 {
                return
             }

            if media?.subitems?.count ?? 0 > 0 {
                stop()
                media = media?.subitems?.media(atIndex: 0)
                play()
                reattemptedConnections += 1
             }

            return
          }

        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      }
}
