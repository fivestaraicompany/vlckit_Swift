import Foundation
import QuartzCore

public extension VLCVideoLayer {
     @objc var hasVideo: Bool { _hasVideo }
    
     @objc var fillScreen: Bool {
         get { (layoutManager as? VLCVideoLayoutManager)?.fillScreenEntirely ?? false }
         set { (layoutManager as? VLCVideoLayoutManager)?.fillScreenEntirely = newValue; setNeedsLayout() }
     }
    
    private var _hasVideo: Bool = false
    
    override public class var layerClass: AnyClass { CALayer.self }
    
     @objc func addVoutLayer(_ aLayer: CALayer) {
         CATransaction.begin()
         aLayer.name = "vlcopengllayer"
         let layoutManager = VLCVideoLayoutManager.layoutManager()
         layoutManager.originalVideoSize = aLayer.bounds.size
         layoutManager.fillScreenEntirely = fillScreen
         self.layoutManager = layoutManager
         insertSublayer(aLayer, at: 0)
         setNeedsDisplayOnBoundsChange(true)
         CATransaction.commit()
         willChangeValue(forKey: "hasVideo")
         _hasVideo = true
         didChangeValue(forKey: "hasVideo")
     }
    
     @objc func removeVoutLayer(_ voutLayer: CALayer) {
         CATransaction.begin()
         voutLayer.removeFromSuperlayer()
         CATransaction.commit()
         willChangeValue(forKey: "hasVideo")
         _hasVideo = false
         didChangeValue(forKey: "hasVideo")
     }
}
