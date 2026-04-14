//
//  VLCMediaMetaData.swift
//  VLCKit
//
//  VLCMediaMetaData - Media metadata for VLC
//

import Foundation

/**
 VLCMediaMetaData - Media metadata for VLC
 */
public class VLCMediaMetaData: NSObject {

    private let _media: VLCMedia
    private var _metaDictionary: [String: Any]

    /**
     Create a new media metadata object
     */
    public init(media: VLCMedia) {
        self._media = media
        self._metaDictionary = [:]
        super.init()
    }

    /// Get metadata for key
    public func getMetadata(forKey key: String) -> String? {
        guard let value = libvlc_media_get_meta(_media._media, stringToMetaType(key)) else {
            return nil
        }
        let result = String(cString: value)
        free(value)
        return result
    }

    /// Set metadata
    public func setMetadata(_ data: String, forKey key: String) {
        guard let media = _media._media else { return }
        libvlc_media_set_meta(media, stringToMetaType(key), data)
    }

    /// Save metadata
    public var saveMetadata: Bool {
        guard let media = _media._media else { return false }
        return libvlc_media_save_meta(media) != 0
    }

    /// Metadata for key (deprecated, use getMetadata instead)
    @available(*, deprecated, message: "Use getMetadata(forKey:) instead")
    public func metadata(forKey key: String) -> String? {
        return getMetadata(forKey: key)
    }

    /// Set metadata (deprecated, use setMetadata(_:forKey:) instead)
    @available(*, deprecated, message: "Use setMetadata(_:forKey:) instead")
    public func setMetadata(_ data: String, forKey key: String) {
        setMetadata(data, forKey: key)
    }
}

// MARK: - VLCMedia Extension

extension VLCMedia {
    /// Convert a string key to VLC media meta type
    static func stringToMetaType(_ key: String) -> UnsafePointer<CChar> {
        let metaType: String
        switch key {
        case "title":
            metaType = "Title"
        case "artist":
            metaType = "Artist"
        case "genre":
            metaType = "Genre"
        case "copyright":
            metaType = "Copyright"
        case "album":
            metaType = "Album"
        case "tracknumber":
            metaType = "Track number"
        case "description":
            metaType = "Description"
        case "rating":
            metaType = "Rating"
        case "date":
            metaType = "Date"
        case "set":
            metaType = "Set"
        case "url":
            metaType = "URL"
        case "license":
            metaType = "License"
        case "trackid":
            metaType = "Track ID"
        default:
            metaType = key
        }
        return strdup(metaType)
    }
}
