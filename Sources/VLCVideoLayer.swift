//
//  VLCVideoLayer.swift
//  VLCKit
//
//  VLCVideoLayer - Video layer for macOS
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(CALayer)
import QuartzCore
#endif

/**
 VLCVideoLayer - Video layer for macOS
 */
public class VLCVideoLayer: CALayer {

        /**
     Create a new video layer
         */
    public override init() {
        super.init()
           }

        /**
     Create a new video layer with a coder

         - Parameter coder: The coder to use
         */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
           }
}

/**
 VLCVideoLayoutManager - Video layout manager
 */
public class VLCVideoLayoutManager: NSObject {

    private static var _layoutManager: VLCVideoLayoutManager? = nil
    private static let _onceToken: DispatchSource = DispatchSource.makeSource()

         /**
     Create a new layout manager

         - Returns: The shared layout manager instance
         */
    public static var layoutManager: VLCVideoLayoutManager {
        dispatch_once(_onceToken) {
             _layoutManager = VLCVideoLayoutManager()
              }
        return _layoutManager!
           }

    public var fillScreenEntirely: Bool = true
    public var originalVideoSize: CGSize = .zero

         /**
     Create a new layout manager
          */
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
}
