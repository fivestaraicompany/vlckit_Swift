import Foundation

public extension VLCStreamSession {
       @objc static func streamSession() -> VLCStreamSession { VLCStreamSession() }
    
       @objc var streamOutput: VLCStreamOutput? {
           get { _streamOutput }
           set { _streamOutput = newValue }
        }
    private var _streamOutput: VLCStreamOutput?
    
       @objc var isComplete: Bool {
           get { _isComplete }
           set { willChangeValue(forKey: "isComplete"); _isComplete = newValue; didChangeValue(forKey: "isComplete") }
        }
    private var _isComplete: Bool = false
    
       @objc var reattemptedConnections: UInt {
           get { _reattemptedConnections }
           set { _reattemptedConnections = newValue }
        }
    private var _reattemptedConnections: UInt = 0
    
       @objc func startStreaming() {
           isComplete = false
           play()
        }
    
       @objc func stopStreaming() {
           isComplete = true
           super.stop()
        }
    
       @objc func play() {
           guard let streamOutput = streamOutput else { super.play(); return }
           let libvlcArgs = "#duplicate{dst=display,dst=\"\(streamOutput.representedLibVLCOptions())\"}"
           super.setMedia(VLCMedia(mediaWithMedia: media, andLibVLCOptions: ["sout": libvlcArgs]))
           super.play()
        }
    
       @objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
           if keyPath == "state" {
               if ((position == 1.0 || (state == VLCMediaPlayerState.error && self.media != nil)) || isComplete) && super.media?.subitems == nil {
                   isComplete = true
                   return
                }
               if reattemptedConnections > 4 { return }
               if let subitems = super.media?.subitems, subitems.count > 0 {
                   stop()
                   media = subitems.media(at: 0)
                   play()
                   reattemptedConnections += 1
                }
               return
            }
           super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
}
