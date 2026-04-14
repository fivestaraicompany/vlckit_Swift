//
//  VLCVideoView.swift
//  VLCKit
//
//  VLCVideoView - Video view for macOS
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import QuartzCore

/**
 VLCVideoView - Video view for macOS
 */
public class VLCVideoView: NSView {

    public private(set) var hasVideo: Bool = false
    public var backColor: NSColor = NSColor.black

    public var fillScreen: Bool = false

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        backColor = NSColor.black
        autoresizesSubviews = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backColor = NSColor.black
        autoresizesSubviews = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        backColor.setFill()
        dirtyRect.fill()
    }

    public override var isOpaque: Bool {
        return true
    }

    public func addVoutLayer(_ aLayer: CALayer) {
        aLayer.name = "vlcopengllayer"

        CATransaction.begin()

        wantsLayer = true
        layer?.insertSublayer(aLayer, at: 0)
        aLayer.needsDisplayOnBoundsChange = true

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

#endif
