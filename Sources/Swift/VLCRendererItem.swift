//
//  VLCRendererItem.swift
//  VLCKit
//
//  VLCRendererItem - Renderer item
//

import Foundation

/**
 VLCRendererItem - Renderer item for VLC
 */
public class VLCRendererItem: NSObject {

    private var _rendererItem: OpaquePointer?

    public private(set) var name: String = ""
    public private(set) var type: String = ""
    public private(set) var iconURI: String = ""
    public private(set) var flags: UInt32 = 0

    /**
     Create a new renderer item
     */
    public override init() {
        super.init()
    }

    /**
     Initialize with a renderer item

     - Parameter item: The renderer item instance
     - Returns: A new renderer item instance
     */
    public init?(rendererItem: OpaquePointer?) {
        guard let item = rendererItem else {
            NSAssert(false, "Renderer item is NULL")
            return nil
        }

        _rendererItem = libvlc_renderer_item_hold(item)

         name = String(cString: libvlc_renderer_item_name(_rendererItem))
         NSAssert(!name.isEmpty, "VLCRendererItem: name is NULL")

         type = String(cString: libvlc_renderer_item_type(_rendererItem))
         NSAssert(!type.isEmpty, "VLCRendererItem: type is NULL")

         iconURI = String(cString: libvlc_renderer_item_icon_uri(_rendererItem))
         NSAssert(!iconURI.isEmpty, "VLCRendererItem: iconURI is NULL")

         flags = libvlc_renderer_item_flags(_rendererItem)

        super.init()
    }

    deinit {
        if let item = _rendererItem {
            libvlc_renderer_item_release(item)
        }
    }

    public override var description: String {
        return "\(type(of: self)) - name: \(name) type: \(type) flags: \(flags)"
    }

    public func libVLCRendererItem() -> OpaquePointer? {
        return _rendererItem
    }
}
