//
//  VLCVideoCommon.swift
//  VLCKit
//
//  VLCVideoCommon - Video common utilities
//

import Foundation
import CoreGraphics
#if canImport(QuartzCore)
import QuartzCore
#endif

/**
 VLCVideoCommon - Video common utilities for VLC
 */
public class VLCVideoCommon: NSObject {

    public var originalVideoSize: CGSize = CGSize.zero
    public var fillScreenEntirely: Bool = false

    public override init() {
        super.init()
    }
}
