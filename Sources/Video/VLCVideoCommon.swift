import Foundation
import QuartzCore

// MARK: - Layout manager
public extension VLCVideoLayoutManager {
         @objc static func layoutManager() -> VLCVideoLayoutManager {
         struct Static {
             static var onceToken: dispatch_once_t = 0
             static var layoutManager: VLCVideoLayoutManager? = nil
         }
         
         dispatch_once(&Static.onceToken) {
             Static.layoutManager = VLCVideoLayoutManager()
         }
         return Static.layoutManager!
     }
    
         @objc var fillScreenEntirely: Bool {
         get { _fillScreenEntirely }
         set {
             _fillScreenEntirely = newValue
             setNeedsLayout()
         }
     }
    
         @objc var originalVideoSize: CGSize {
         get { _originalVideoSize }
         set {
             _originalVideoSize = newValue
             setNeedsLayout()
         }
     }
    
     private var _fillScreenEntirely: Bool = false
     private var _originalVideoSize: CGSize = .zero
    
     override public func layoutSublayers(of layer: CALayer) {
         guard let sublayers = layer.sublayers, sublayers.count > 0,
               sublayers[0].name == "vlcopengllayer" else {
             return
         }
         
         let videoLayer = sublayers[0]
         let bounds = layer.bounds
         var videoRect = bounds
         let original = originalVideoSize
         
         if original.height > 0 && original.width > 0 {
             let xRatio = bounds.width / original.width
             let yRatio = bounds.height / original.height
             let ratio = fillScreenEntirely ? max(xRatio, yRatio) : min(xRatio, yRatio)
             
             videoRect.size.width = ratio * original.width
             videoRect.size.height = ratio * original.height
             videoRect.origin.x += (bounds.width - videoRect.width) / 2.0
             videoRect.origin.y += (bounds.height - videoRect.height) / 2.0
         }
         
         videoLayer.frame = videoRect
     }
}
