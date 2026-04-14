//
//  VLCMediaMetaData.swift
//  VLCKit
//
//  VLCMediaMetaData - Media metadata for VLC
//

import Foundation
import CLibVLC

/**
 VLCMediaMetaData - Media metadata for VLC
 */
public class VLCMediaMetaData: NSObject {

    private weak var _media: VLCMedia?

    /**
     Create a new media metadata object
     */
    public init(media: VLCMedia) {
        self._media = media
        super.init()
    }

    /// Get metadata for key
    public func getMetadata(forKey key: String) -> String? {
        guard let descriptor = _media?.libVLCMediaDescriptor else { return nil }
        let metaType = VLCMedia.stringToMetaType(key)
        guard let value = libvlc_media_get_meta(descriptor, metaType) else {
            return nil
        }
        let result = String(cString: value)
        return result
    }

    /// Set metadata
    public func setMetadata(_ data: String, forKey key: String) {
        guard let descriptor = _media?.libVLCMediaDescriptor else { return }
        libvlc_media_set_meta(descriptor, VLCMedia.stringToMetaType(key), data)
    }

    /// Save metadata
    public func save() -> Bool {
        guard let descriptor = _media?.libVLCMediaDescriptor else { return false }
        return libvlc_media_save_meta(descriptor) != 0
    }
}
