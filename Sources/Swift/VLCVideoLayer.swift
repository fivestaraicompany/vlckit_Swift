//
//  VLCVideoLayer.swift
//  VLCKit
//
//  VLCVideoLayer - Video layer for macOS
//

import Foundation
import CoreGraphics
#if canImport(QuartzCore)
import QuartzCore
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/**
 VLCVideoLayer - Video layer for macOS
 */
public class VLCVideoLayer: CALayer {

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/**
 VLCVideoLayoutManager - Video layout manager
 */
public class VLCVideoLayoutManager: NSObject, CALayoutManager {

    public static let shared = VLCVideoLayoutManager()

    public var fillScreenEntirely: Bool = true
    public var originalVideoSize: CGSize = .zero

    public override init() {
        super.init()
    }

    public func layoutSublayers(of layer: CALayer) {
        guard let sublayers = layer.sublayers, !sublayers.isEmpty,
              let firstSublayer = sublayers.first,
              firstSublayer.name == "vlcopengllayer" else {
            return
        }

        let videolayer = firstSublayer
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

        videolayer.frame = videoRect
    }

    public func invalidateLayout(of layer: CALayer) {
        // Nothing to do
    }

    public func preferredSize(of layer: CALayer) -> CGSize {
        return layer.bounds.size
    }
}

#endif
