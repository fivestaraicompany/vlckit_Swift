//
//  VLCRendererItem.swift
//  VLCKit
//
//  VLCRendererItem - Renderer item
//

import Foundation
import CLibVLC

/**
 VLCRendererItem - Renderer item for VLC
 */
public class VLCRendererItem: NSObject {

    private var _rendererItem: OpaquePointer?

    public private(set) var name: String = ""
    public private(set) var type: String = ""
    public private(set) var iconURI: String = ""
    public private(set) var flags: Int32 = 0

    /// Access the underlying libvlc renderer item
    public var libVLCRendererItem: OpaquePointer? {
        return _rendererItem
    }

    public override init() {
        super.init()
    }

    public init?(rendererItem: OpaquePointer?) {
        guard let item = rendererItem else {
            return nil
        }

        _rendererItem = libvlc_renderer_item_hold(item)

        if let namePtr = libvlc_renderer_item_name(_rendererItem) {
            name = String(cString: namePtr)
        }
        if let typePtr = libvlc_renderer_item_type(_rendererItem) {
            type = String(cString: typePtr)
        }
        if let iconPtr = libvlc_renderer_item_icon_uri(_rendererItem) {
            iconURI = String(cString: iconPtr)
        }
        flags = libvlc_renderer_item_flags(_rendererItem)

        super.init()
    }

    deinit {
        if let item = _rendererItem {
            libvlc_renderer_item_release(item)
        }
    }

    public override var description: String {
        return "\(Swift.type(of: self)) - name: \(name) type: \(type) flags: \(flags)"
    }
}
