import Foundation
import Metal
import CoreVideo

#if canImport(Metal) && (os(macOS) || os(iOS) || os(tvOS))

/// Describes a video frame texture from libvlc
public struct VLCMetalVideoFrame {
    public let texture: MTLTexture
    public let width: Int32
    public let height: Int32
    public let format: MTLPixelFormat
    public let chroma: String
    
    public init(texture: MTLTexture, width: Int32, height: Int32, format: MTLPixelFormat, chroma: String) {
        self.texture = texture
        self.width = width
        self.height = height
        self.format = format
        self.chroma = chroma
    }
}

/// Metal-based video renderer that draws frames directly using Metal
@objc public final class VLCMetalTextureRenderer: NSObject {
    
    /// The Metal device used for rendering
    @objc public let device: MTLDevice
    
    /// The Metal command queue
    @objc public let commandQueue: MTLCommandQueue
    
    /// The render pipeline state for drawing video frames
    @objc public private(set) var renderPipeline: MTLRenderPipelineState?
    
    /// The display link for frame presentation
    @objc public private(set) var displayLink: CADisplayLink?
    
    /// Whether the renderer is actively rendering
    @objc public var isRunning: Bool { displayLink != nil }
    
    /// The delegate to receive frame notifications
    @objc public weak var delegate: VLCMetalTextureRendererDelegate?
    
    private let renderPassDescriptor: MTLRenderPassDescriptor
    private let vertexDescriptor: MTLVertexDescriptor
    private var drawable: MTLDrawable?
    private var drawableIndex: Int = 0
    private let maxDrawableCount = 3
    
    /// Metal buffer for vertex data (full-screen quad)
    private var vertexBuffer: MTLBuffer?
    
    /// Pixel conversion compute pipelines (one per chroma format)
    private var yuvConversionPipelines: [String: MTLComputePipelineState] = [:]
    
    /// Queue for thread safety
    private let rendererQueue = DispatchQueue(label: "org.videolan.VLCKit.MetalRenderer", attributes: .concurrent)
    
    /// Callback that receives raw video frames from libvlc
    @objc public var videoFrameCallback: (() -> VLCMetalVideoFrame)?
    
    /// Size of the drawable
    private var drawableSize: CGSize = .zero
    
    // MARK: - Initialization
    
    @objc public convenience init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.init(device: device)
    }
    
    @objc public init(device: MTLDevice) {
        self.device = device
        self.vertexDescriptor = VLCMetalTextureRenderer.createVertexDescriptor()
        self.renderPassDescriptor = MTLRenderPassDescriptor()
        
        super.init()
        setupMetal()
    }
    
    deinit {
        stopRendering()
    }
    
    // MARK: - Setup
    
    private func setupMetal() {
        // Create command queue
        guard let queue = device.makeCommandQueue() else {
            delegate?.metalRendererDidStop(self)
            return
        }
        commandQueue = queue
        
        // Create vertex buffer (full-screen quad with texture coordinates)
        let vertices: [Float] = [
            // Position         // Texture coord
            -1.0, -1.0,         0.0, 1.0,
             1.0, -1.0,         1.0, 1.0,
            -1.0,   1.0,         0.0, 0.0,
             1.0,   1.0,         1.0, 0.0,
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size)
        
        // Create YUV conversion compute pipelines
        createYUVConversionPipelines()
    }
    
    /// Create compute pipelines for YUV to RGB conversion
    private func createYUVConversionPipelines() {
        guard let library = device.makeDefaultLibrary() else { return }
        
        // I420 / IYUV -> RGB conversion
        if let pipeline = device.makeComputePipelineState(
            shaderFunction: library.makeFunction(name: "yuv420ToRGB"),
            options: nil,
            reflection: nil
        ) {
            yuvConversionPipelines["I420"] = pipeline
            yuvConversionPipelines["IYUV"] = pipeline
        }
        
        // NV12 / NV21 -> RGB conversion
        if let pipeline = device.makeComputePipelineState(
            shaderFunction: library.makeFunction(name: "nv12ToRGB"),
            options: nil,
            reflection: nil
        ) {
            yuvConversionPipelines["NV12"] = pipeline
            yuvConversionPipelines["NV21"] = pipeline
        }
        
        // YUVA420 -> RGBA conversion
        if let pipeline = device.makeComputePipelineState(
            shaderFunction: library.makeFunction(name: "yuva420ToRGBA"),
            options: nil,
            reflection: nil
        ) {
            yuvConversionPipelines["YUVA"] = pipeline
        }
    }
    
    /// Create the Metal vertex descriptor for the render pipeline
    private static func createVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        
        // Position attribute (location 0)
        descriptor.attributes[0].format = .float2
        descriptor.attributes[0].offset = 0
        descriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinate attribute (location 1)
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        descriptor.attributes[1].bufferIndex = 0
        
        // Buffer layout
        descriptor.bufferStates[0].stride = MemoryLayout<Float>.size * 4
        descriptor.bufferStates[0].arrayStride = MemoryLayout<Float>.size * 4
        descriptor.bufferStates[0].usage = .vertexBuffer
        
        return descriptor
    }
    
    // MARK: - Rendering
    
    /// Draw using the render pipeline for a single texture
    private func drawTexture(texture: MTLTexture, drawable: MTLDrawable) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let pipeline = renderPipeline ?? createVideoRenderPipeline() else {
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }
        
        guard let renderPass = renderPassDescriptor else { return }
        renderPass.colorAttachments[0].texture = drawable.texture
        renderPass.colorAttachments[0].loadAction = .clear
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else { return }
        
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        
        // Draw the full-screen quad (4 vertices = triangle strip)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// Draw using YUV compute shaders for proper color space conversion
    @objc public func renderYUV(frame: VLCMetalVideoFrame, drawable: MTLDrawable, width: Int, height: Int) {
        rendererQueue.async { [weak self] in
            guard let self = self,
                  let commandBuffer = self.commandQueue.makeCommandBuffer(),
                  let pipeline = self.yuvConversionPipelines[frame.chroma] else {
                commandBuffer.present(drawable)
                commandBuffer.commit()
                return
            }
            
            // Set up render pass with drawable texture as output
            guard let renderPass = self.renderPassDescriptor else { return }
            renderPass.colorAttachments[0].texture = drawable.texture
            renderPass.colorAttachments[0].loadAction = .clear
            renderPass.colorAttachments[0].storeAction = .store
            renderPass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            
            computeEncoder.setComputePipelineState(pipeline)
            computeEncoder.setTexture(frame.texture, index: 0)
            computeEncoder.setTexture(drawable.texture, index: 1)
            
            // Dispatch threads in 8x8 tile groups
            let threadsPerGroup = MTLSize(width: 8, height: 8, depth: 1)
            let threadGroups = MTLSize(
                width: UInt(((width + 7) / 8)),
                height: UInt(((height + 7) / 8)),
                depth: 1
            )
            
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    /// Create the video render pipeline for texture sampling
    private func createVideoRenderPipeline() -> MTLRenderPipelineState? {
        guard let library = device.makeDefaultLibrary() else { return nil }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "videoVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "videoFragmentShader")
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = false
        
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            delegate?.metalRenderer(self, didError: error)
            return nil
        }
    }
    
    // MARK: - Display Link
    
    @objc public func startRendering(in view: NSView) {
        guard displayLink == nil else { return }
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink.add(to: .main, forMode: .default)
        self.displayLink = displayLink
        delegate?.metalRendererDidStart(self)
    }
    
    @objc public func stopRendering() {
        rendererQueue.async { [weak self] in
            self?.displayLink?.invalidate()
            self?.displayLink = nil
            self?.drawable = nil
            DispatchQueue.main.async {
                self?.delegate?.metalRendererDidStop(self!)
            }
        }
    }
    
    @objc private func displayLinkFired() {
        guard let drawable = drawable, let frame = videoFrameCallback?() else { return }
        delegate?.metalRenderer(self, didProvideFrame: frame)
        renderYUV(frame: frame, drawable: drawable, width: Int(frame.width), height: Int(frame.height))
    }
    
    // MARK: - Public API
    
    /// Present a drawable (called by the host view's layer)
    @objc public func present(drawable: MTLDrawable) {
        self.drawable = drawable
    }
    
    /// Get the Metal layer configured for this renderer
    @objc public var metalLayer: CAMetalLayer {
        let layer = CAMetalLayer()
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.drawableSize = drawableSize
        return layer
    }
    
    /// Update the drawable size for the renderer
    @objc public func updateDrawableSize(_ size: CGSize) {
        rendererQueue.async { [weak self] in
            self?.drawableSize = size
        }
    }
}

/// Delegate protocol for Metal texture renderer events
@objc public protocol VLCMetalTextureRendererDelegate: AnyObject {
    /// Called when a new video frame is available for rendering
    @objc optional func metalRenderer(_ renderer: VLCMetalTextureRenderer, didProvideFrame frame: VLCMetalVideoFrame)
    
    /// Called when rendering starts
    @objc optional func metalRendererDidStart(_ renderer: VLCMetalTextureRenderer)
    
    /// Called when rendering stops
    @objc optional func metalRendererDidStop(_ renderer: VLCMetalTextureRenderer)
    
    /// Called when an error occurs
    @objc optional func metalRenderer(_ renderer: VLCMetalTextureRenderer, didError error: Error)
}

#endif // Metal support
