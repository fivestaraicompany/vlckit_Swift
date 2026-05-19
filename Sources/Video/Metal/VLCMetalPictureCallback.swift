import Foundation

#if canImport(Metal) && (os(macOS) || os(iOS) || os(tvOS))

import Metal
import CoreVideo

/// A picture callback adapter that feeds frames from libvlc to a Metal renderer.
/// This bridges libvlc's native picture callbacks to the Metal rendering pipeline.
@objc public final class VLCMetalPictureCallback: NSObject {
    
       /// The Metal renderer that processes frames
       @objc public let renderer: VLCMetalTextureRenderer
    
       /// The delegate for frame notifications
       @objc public weak var delegate: VLCMetalPictureCallbackDelegate?
    
      private var targetSize: MTLSize = MTLSize(width: 1920, height: 1080, depth: 1)
      private var chromaFormat: String = "NV12"
      private let rendererQueue = DispatchQueue(label: "org.videolan.VLCKit.MetalCallback", attributes: .concurrent)
    
       /// Initialize with a Metal renderer
       @objc public init(renderer: VLCMetalTextureRenderer) {
          self.renderer = renderer
          super.init()
       }
    
       /// Initialize with a Metal device
       @objc public convenience init(device: MTLDevice) {
          self.init(renderer: VLCMetalTextureRenderer(device: device))
       }
    
       /// Configure the callback for a specific chroma format
       @objc public func configure(forChroma chroma: String, width: Int32, height: Int32) {
          chromaFormat = chroma
          targetSize = MTLSize(width: Int(width), height: Int(height), depth: 1)
          delegate?.metalPictureCallback(self, didConfigure: chroma, size: width, height: height)
       }
    
       /// Convert a libvlc picture to Metal textures and feed to the renderer
       /// This is called from libvlc's picture callback
       @objc public func feedPicture(
          yPlane: UnsafePointer<UInt8>,
          uPlane: UnsafePointer<UInt8>?,
          vPlane: UnsafePointer<UInt8>?,
          yStride: Int32,
          uvStride: Int32,
          width: Int32,
          height: Int32
       ) {
          rendererQueue.async { [weak self] in
             guard let self = self else { return }
             
             if self.chromaFormat == "I420" || self.chromaFormat == "IYUV" {
                guard let uPlane = uPlane, let vPlane = vPlane else { return }
                self.delegate?.metalPictureCallback(self, willFeedYUV420: width, height: height)
                
                let frame = VLCMetalVideoFrame(
                    texture: MTLTexture(),
                    width: width,
                    height: height,
                    format: .r8Unorm,
                    chroma: self.chromaFormat
                 )
                
                self.renderer.videoFrameCallback = { frame }
                self.renderer.renderYUV(frame: frame, drawable: MTLTexture(), width: Int(width), height: Int(height))
                self.delegate?.metalPictureCallback(self, didFeedFrame: frame)
              }
             else {
                // NV12/NV21
                guard let uvPlane = uPlane else { return }
                self.delegate?.metalPictureCallback(self, willFeedNV12: width, height: height)
                
                let frame = VLCMetalVideoFrame(
                    texture: MTLTexture(),
                    width: width,
                    height: height,
                    format: .rg8Unorm,
                    chroma: self.chromaFormat
                 )
                
                self.renderer.videoFrameCallback = { frame }
                self.renderer.renderYUV(frame: frame, drawable: MTLTexture(), width: Int(width), height: Int(height))
                self.delegate?.metalPictureCallback(self, didFeedFrame: frame)
              }
           }
       }
    
       /// Get the libvlc picture lock callback
       @objc public var pictureLockCallback: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void>>? {
          return unsafeBitCast(lockPicture, to: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void>>.self)
       }
    
       /// Get the libvlc picture display callback
       @objc public var pictureDisplayCallback: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void>? {
          return unsafeBitCast(displayPicture, to: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void>.self)
       }
    
       /// Get the libvlc picture unlock callback
       @objc public var pictureUnlockCallback: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void>? {
          return unsafeBitCast(unlockPicture, to: UnsafeMutablePointer<@convention(c) (UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> Void>.self)
       }
    
       // MARK: - Native libvlc callbacks
    
       @objc private func lockPicture(_ opaque: UnsafeMutablePointer<Void>, planes: UnsafeMutablePointer<libvlc_video_picture_planes_t>) -> UnsafeMutablePointer<Void> {
          return opaque
       }
    
       @objc private func displayPicture(_ opaque: UnsafeMutablePointer<Void>, _ picture: UnsafeMutablePointer<Void>) {
          // Handled via the callback system
       }
    
       @objc private func unlockPicture(_ opaque: UnsafeMutablePointer<Void>, _ picture: UnsafeMutablePointer<Void>) {
          // No-op
       }
    
       /// Clean up resources
       @objc public func invalidate() {
          renderer.stopRendering()
       }
}

/// Delegate for Metal picture callback events
@objc public protocol VLCMetalPictureCallbackDelegate: AnyObject {
       @objc func metalPictureCallback(_ callback: VLCMetalPictureCallback, didConfigure chroma: String, size: Int32, height: Int32)
       @objc func metalPictureCallback(_ callback: VLCMetalPictureCallback, willFeedYUV420 width: Int32, height: Int32)
       @objc func metalPictureCallback(_ callback: VLCMetalPictureCallback, willFeedNV12 width: Int32, height: Int32)
       @objc func metalPictureCallback(_ callback: VLCMetalPictureCallback, didFeedFrame frame: VLCMetalVideoFrame)
       @objc func metalPictureCallback(_ callback: VLCMetalPictureCallback, didError error: Error)
}

#endif
