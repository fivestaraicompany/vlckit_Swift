import Foundation
import AppKit
import QuartzCore

public extension VLCVideoView {
     @objc var backColor: NSColor {
         get { _backColor ?? NSColor.black }
         set { _backColor = newValue; setNeedsDisplay(bounds) }
     }
    private var _backColor: NSColor?
    
     @objc var fillScreen: Bool {
         get { layoutManager?.fillScreenEntirely ?? false }
         set { layoutManager?.fillScreenEntirely = newValue; layer?.setNeedsLayout() }
     }
    
     @objc var hasVideo: Bool { _hasVideo }
    private var _hasVideo: Bool = false
    private var layoutManager: VLCVideoLayoutManager?
    
     @objc override init(frame: NSRect) {
         super.init(frame: frame)
         self.backColor = NSColor.black
         self.autoresizesSubviews = true
         self.layoutManager = VLCVideoLayoutManager.layoutManager()
     }
    
     @objc required init?(coder: NSCoder) {
         super.init(coder: coder)
         self.backColor = NSColor.black
         self.autoresizesSubviews = true
         self.layoutManager = VLCVideoLayoutManager.layoutManager()
     }
    
     @objc override var isOpaque: Bool { true }
    
     @objc override func draw(_ rect: NSRect) {
         backColor.set()
         NSRectFill(rect)
     }
    
     @objc func addVoutLayer(_ aLayer: CALayer) {
         aLayer.name = "vlcopengllayer"
         CATransaction.begin()
         wantsLayer = true
         let rootLayer = self.layer!
         layoutManager?.originalVideoSize = aLayer.bounds.size
         rootLayer.layoutManager = layoutManager
         rootLayer.insertSublayer(aLayer, at: 0)
         aLayer.setNeedsDisplayOnBoundsChange(true)
         CATransaction.commit()
         _hasVideo = true
     }
    
     @objc func removeVoutLayer(_ voutLayer: CALayer) {
         CATransaction.begin()
         voutLayer.removeFromSuperlayer()
         CATransaction.commit()
         _hasVideo = false
     }
}
