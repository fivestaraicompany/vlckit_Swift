//
//  VLCVideoView.swift
//  VLCKit
//
//  VLCVideoView - Video view for macOS
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(CALayer)
import QuartzCore
#endif

/**
 VLCVideoView - Video view for macOS
 */
public class VLCVideoView: NSView {

    public private(set) var layoutManager: VLCVideoLayoutManager = VLCVideoLayoutManager()
    public private(set) var hasVideo: Bool = false
    public var backColor: NSColor = NSColor.black

    public var fillScreen: Bool {
        get { layoutManager.fillScreenEntirely }
        set { layoutManager.fillScreenEntirely = newValue }
        }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        backColor = NSColor.black
        autoresizesSubviews = true
        layoutManager = VLCVideoLayoutManager()
        }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backColor = NSColor.black
        autoresizesSubviews = true
        layoutManager = VLCVideoLayoutManager()
        }

    public override func draw(_ rect: NSRect) {
        self.lockFocus()
        backColor.set()
        NSRectFill(rect)
        self.unlockFocus()
        }

    public override var isOpaque: Bool {
        return true
        }

    public func addVoutLayer(_ aLayer: CALayer) {
        aLayer.name = "vlcopengllayer"

        CATransaction.begin()

        wantsLayer = true
        let rootLayer = self.layer
        rootLayer?.layoutManager = layoutManager
        rootLayer?.insertSublayer(aLayer, at: 0)
        aLayer.setNeedsDisplay(onBoundsChange: true)

        CATransaction.commit()

        hasVideo = true
        }

    public func removeVoutLayer(_ voutLayer: CALayer) {
        CATransaction.begin()
        voutLayer.removeFromSuperlayer()
        CATransaction.commit()

        hasVideo = false
        }
}

/**
 VLCOpenGLVoutView - OpenGL vout view (deprecated)
 */
public class VLCOpenGLVoutView: NSView {

    public func detachFromVout() {
        // Deprecated
        }
}
