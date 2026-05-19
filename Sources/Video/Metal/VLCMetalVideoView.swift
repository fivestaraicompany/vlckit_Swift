import Foundation

#if canImport(Metal) && os(macOS)

import AppKit
import Metal
import MetalKit

/// A macOS NSView subclass that renders video using Metal.
/// Provides a GPU-accelerated alternative to the default OpenGL-based VLCVideoView.
@objc public final class VLCMetalVideoView: NSView, VLCMetalVideoViewDelegate {
    
     /// The Metal device used for rendering
     @objc public var device: MTLDevice? { metalLayer?.device }
    
     /// The Metal layer backing this view
     @objc public private(set) var metalLayer: CAMetalLayer!
    
     /// The Metal renderer that handles YUV conversion and presentation
     @objc public private(set) var renderer: VLCMetalTextureRenderer?
    
     /// The Metal trackable object for synchronization
    private var drawable: MTLDrawable?
    
     /// Frame buffer for YUV conversion
    private var yuvTexture: MTLTexture?
    private var rgbTexture: MTLTexture?
    
     /// Video dimensions
    private var videoWidth: Int32 = 0
    private var videoHeight: Int32 = 0
    private var chroma: String = "NV12"
    
     /// Whether Metal rendering is enabled
     @objc public var isMetalEnabled: Bool {
        get { renderer != nil }
        set {
            if newValue && renderer == nil {
                enableMetal()
            } else if !newValue {
                disableMetal()
            }
        }
    }
    
    // MARK: - Initialization
    
    @objc public override init(frame: NSRect) {
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
    
    // MARK: - Setup
    
    private func setupLayer() {
        wantsLayer = true
        metalLayer = CAMetalLayer()
        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        layer = metalLayer
    }
    
    private func enableMetal() {
        guard renderer == nil else { return }
        
        renderer = VLCMetalTextureRenderer()
        renderer?.delegate = self
        renderer?.startRendering(in: self)
    }
    
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
    
    // MARK: - Drawing
    
    private func prepareTextures(width: Int32, height: Int32) {
        guard let device = device else { return }
        
        let size = MTLSize(width: Int(width), height: Int(height), depth: 1)
        
         // Y plane
        yuvTexture = device.makeTexture(
            descriptor: MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .r8Unorm,
                width: Int(width),
                height: Int(height),
                mipmapped: false
             )
         )
        
         // Chroma plane (UV interleaved for NV12)
        let chromaWidth = Int(width) / 2
        let chromaHeight = Int(height) / 2
        let chromaDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rg8Unorm,
            width: chromaWidth,
            height: chromaHeight,
            mipmapped: false
         )
        let chromaTexture = device.makeTexture(descriptor: chromaDescriptor)
        
         // Full RGB output texture
        rgbTexture = device.makeTexture(
            descriptor: MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: Int(width),
                height: Int(height),
                mipmapped: false
             )
         )
    }
    
    /// Feed a raw YUV frame to the Metal renderer
    @objc public func feedYUVFrame(
        yData: UnsafePointer<UInt8>,
        uData: UnsafePointer<UInt8>,
        vData: UnsafePointer<UInt8>,
        yStride: Int32,
        uvStride: Int32,
        width: Int32,
        height: Int32
    ) {
        self.videoWidth = width
        self.videoHeight = height
        self.chroma = "I420"
        
        guard let yuvTexture = yuvTexture,
              let renderer = renderer else { return }
        
        yuvTexture.replace(
            region: MTLRegionMake2D(0, 0, Int(width), Int(height)),
            withBytes: yData,
            bytesPerRow: yStride
         )
        
         // Create combined texture
        let combinedTexture = VLCMetalVideoFrame(
            texture: yuvTexture,
            width: width,
            height: height,
            format: .r8Unorm,
            chroma: "I420"
         )
        
        renderer.videoFrameCallback = { combinedTexture }
        renderer.renderYUV(frame: combinedTexture, drawable: drawable!, width: Int(width), height: Int(height))
    }
    
    /// Feed an NV12/YUV420 frame
    @objc public func feedNV12Frame(
        yData: UnsafePointer<UInt8>,
        uvData: UnsafePointer<UInt8>,
        yStride: Int32,
        uvStride: Int32,
        width: Int32,
        height: Int32
    ) {
        self.videoWidth = width
        self.videoHeight = height
        self.chroma = "NV12"
        
        guard let renderer = renderer else { return }
        
        let combinedTexture = VLCMetalVideoFrame(
            texture: yuvTexture ?? MTLTexture(),
            width: width,
            height: height,
            format: .rg8Unorm,
            chroma: "NV12"
         )
        
        renderer.videoFrameCallback = { combinedTexture }
        renderer.renderYUV(frame: combinedTexture, drawable: drawable!, width: Int(width), height: Int(height))
    }
    
    // MARK: - NSView overrides
    
    @objc public override func resize(withNewLayer newLayer: CALayer) {
        super.resize(withNewLayer: newLayer)
        if let metalLayer = newLayer as? CAMetalLayer {
            metalLayer.drawableSize = newLayer.bounds.size
        }
    }
    
    @objc public override func draw(_ dirtyRect: NSRect) {
        if let drawable = metalLayer?.nextDrawable() {
            self.drawable = drawable
            renderer?.present(drawable: drawable)
        }
    }
}

/// Delegate for VLCMetalVideoView events
@objc public protocol VLCMetalVideoViewDelegate: VLCMetalTextureRendererDelegate {
     /// Called when Metal rendering starts
    @objc func metalVideoViewDidStartMetal(_ view: VLCMetalVideoView)
    
     /// Called when Metal rendering stops
    @objc func metalVideoViewDidStopMetal(_ view: VLCMetalVideoView)
    
     /// Called with each rendered frame for custom processing
    @objc optional func metalVideoView(_ view: VLCMetalVideoView, didRenderFrame drawable: MTLDrawable)
}

#endif // macOS Metal support
