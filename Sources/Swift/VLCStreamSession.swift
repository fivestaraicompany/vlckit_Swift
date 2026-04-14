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

    public override init() {
        super.init()
    }

    public static func streamSession() -> VLCStreamSession {
        return VLCStreamSession()
    }

    public func setStreamMedia(_ newMedia: VLCMedia?) {
        guard let newValue = newMedia else {
            setMedia(nil)
            return
        }

        if let streamOutput = _streamOutput {
            let args = "#duplicate{dst=display,dst=\"\(streamOutput.representedLibVLCOptions())\"}"
            let mediaWithSout = VLCMedia(media: newValue, andLibVLCOptions: ["sout": args])
            setMedia(mediaWithSout)
        } else {
            setMedia(newValue)
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
}
