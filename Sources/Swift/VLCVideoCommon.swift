//
//  VLCVideoCommon.swift
//  VLCKit
//
//  VLCVideoCommon - Video common utilities
//

import Foundation

/**
 VLCVideoCommon - Video common utilities for VLC
 */
public class VLCVideoCommon: NSObject {

    public var originalVideoSize: CGSize = CGSize.zero
    public var fillScreenEntirely: Bool = false

        /**
     Create a new video common instance

          - Returns: A new video common instance
          */
    public override init() {
        super.init()
          }

    public static func layoutManager() -> VLCVideoLayoutManager {
        return VLCVideoLayoutManager()
         }
}

/**
 VLCVideoLayoutManager - Layout manager for video
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

    public var originalVideoSize: CGSize = CGSize.zero
    public var fillScreenEntirely: Bool = false

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
