//
//  VLCAdjustFilter.swift
//  VLCKit
//
//  VLCAdjustFilter - Video adjustment filter
//

import Foundation

/**
 VLCAdjustFilter - Video adjustment filter for VLC
 */
public class VLCAdjustFilter: VLCFilter {

    public var contrast: Float = 1.0
    public var brightness: Float = 1.0
    public var hue: Float = 0.0
    public var saturation: Float = 1.0
    public var gamma: Float = 1.0

    public override init() {
        super.init()
    }

    public override init(name: String, enabled: Bool) {
        super.init(name: name, enabled: enabled)
    }

    public override func reset() {
        super.reset()
        contrast = 1.0
        brightness = 1.0
        hue = 0.0
        saturation = 1.0
        gamma = 1.0
    }
}
