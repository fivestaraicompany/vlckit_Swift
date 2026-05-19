import Foundation

#if canImport(MetalKit) && (os(iOS) || os(tvOS))

import UIKit
import Metal
import MetalKit

/// iOS/tvOS Metal video view - GPU-accelerated rendering
@objc public final class VLCMetalVideoView: UIView, VLCMetalVideoViewDelegate {
    
        /// The Metal device used for rendering
        @objc public var device: MTLDevice? { metalLayer?.device }
     
         /// The Metal layer backing this view
         @objc public private(set) var metalLayer: CAMetalLayer!
     
         /// The Metal renderer that handles frame presentation
         @objc public private(set) var renderer: VLCMetalTextureRenderer?
     
         /// Whether Metal rendering is active
         @objc public var isMetalEnabled: Bool { renderer != nil }
     
         /// Aspect ratio mode for video display
         @objc public var contentMode: VideoContentMode = .aspectFit {
          didSet { layoutSubviews() }
         }
    
         /// Whether video fills the entire screen
         @objc public var fillScreen: Bool = false {
          didSet { layoutSubviews() }
         }
    
         /// Frame dimensions
        private var videoWidth: Int32 = 0
        private var videoHeight: Int32 = 0
    
         /// Drawables queue
        private var drawables: [MTLDrawable] = []
    
         /// Initialization
         @objc public override init(frame: CGRect) {
          super.init(frame: frame)
          setupLayer()
         }
    
         @objc public required init?(coder: NSCoder) {
          super.init(coder: coder)
          setupLayer()
         }
    
        deinit {
          renderer?.stopRendering()
         }
    
         /// Setup the Metal layer
        private func setupLayer() {
          layer = CAMetalLayer()
          guard let ml = layer as? CAMetalLayer else { return }
          ml.device = MTLCreateSystemDefaultDevice()
          ml.pixelFormat = .bgra8Unorm
          ml.framebufferOnly = false
          self.metalLayer = ml
         }
    
         /// Enable Metal rendering
        private func enableMetal() {
          guard renderer == nil else { return }
          renderer = VLCMetalTextureRenderer()
          renderer?.delegate = self
          renderer?.startRendering(in: self)
         }
    
         /// Disable Metal rendering
        private func disableMetal() {
          renderer?.stopRendering()
          renderer = nil
         }
    
         // MARK: - VLCMetalVideoViewDelegate
    
         @objc public func metalVideoViewDidStartMetal(_ view: VLCMetalVideoView) {
              // No-op; delegate can implement this
         }
    
         @objc public func metalVideoViewDidStopMetal(_ view: VLCMetalVideoView) {
              // No-op; delegate can implement this
         }
    
         /// Layout subviews with aspect ratio
          @objc public override func layoutSubviews() {
          super.layoutSubviews()
          let bounds = self.bounds
    
          if fillScreen {
            metalLayer.drawableSize = bounds.size
            return
           }
    
          let videoAR = CGFloat(videoWidth) / max(CGFloat(videoHeight), 1)
          let viewAR = bounds.width / max(bounds.height, 1)
    
          var size = bounds.size
          switch contentMode {
          case .aspectFit:
            if videoAR > viewAR {
              size = CGSize(width: bounds.width, height: bounds.width / videoAR)
             } else {
              size = CGSize(width: bounds.height * videoAR, height: bounds.height)
             }
          case .aspectFill:
            if videoAR > viewAR {
              size = CGSize(width: bounds.height * videoAR, height: bounds.height)
             } else {
              size = CGSize(width: bounds.width, height: bounds.width / videoAR)
             }
          case .fill:
            size = bounds.size
          case .center:
            let w = min(bounds.width, CGFloat(videoWidth))
            let h = min(bounds.height, CGFloat(videoHeight))
            size = CGSize(width: w, height: h)
           }
    
          metalLayer.drawableSize = size
         }
    
         /// Feed a YUV420 frame to the renderer
          @objc public func feedYUVFrame(
            yData: UnsafePointer<UInt8>,
            uData: UnsafePointer<UInt8>,
            vData: UnsafePointer<UInt8>,
            yStride: Int32,
            uvStride: Int32,
            width: Int32,
            height: Int32
         ) {
            videoWidth = width
            videoHeight = height
            guard let renderer = renderer else { return }
    
            let frame = VLCMetalVideoFrame(
                texture: MTLTexture(),
                width: width,
                height: height,
                format: .r8Unorm,
                chroma: "I420"
             )
    
            renderer.videoFrameCallback = { frame }
            renderer.renderYUV(frame: frame, drawable: MTLTexture(), width: Int(width), height: Int(height))
         }
    
         /// Feed an NV12 frame to the renderer
          @objc public func feedNV12Frame(
            yData: UnsafePointer<UInt8>,
            uvData: UnsafePointer<UInt8>,
            yStride: Int32,
            uvStride: Int32,
            width: Int32,
            height: Int32
         ) {
            videoWidth = width
            videoHeight = height
            guard let renderer = renderer else { return }
    
            let frame = VLCMetalVideoFrame(
                texture: MTLTexture(),
                width: width,
                height: height,
                format: .rg8Unorm,
                chroma: "NV12"
             )
    
            renderer.videoFrameCallback = { frame }
            renderer.renderYUV(frame: frame, drawable: MTLTexture(), width: Int(width), height: Int(height))
         }
    
         /// Present the next drawable
          @objc public func presentDrawable() {
            guard let drawable = metalLayer?.nextDrawable() else { return }
            renderer?.present(drawable: drawable)
         }
    
         @objc public override func didMoveToWindow() {
            super.didMoveToWindow()
            if isDescendant(of: window?.rootViewController?.view) {
                enableMetal()
             }
         }
}

/// Content mode for video aspect ratio
public enum VideoContentMode: Int {
    case aspectFit = 0
    case aspectFill = 1
    case fill = 2
    case center = 3
}

/// Delegate for Metal video view
@objc public protocol VLCMetalVideoViewDelegate: VLCMetalTextureRendererDelegate {
     @objc func metalVideoViewDidStartMetal(_ view: VLCMetalVideoView)
     @objc func metalVideoViewDidStopMetal(_ view: VLCMetalVideoView)
     @objc optional func metalVideoView(_ view: VLCMetalVideoView, didRenderFrame drawable: MTLDrawable)
}

#endif // iOS/tvOS
