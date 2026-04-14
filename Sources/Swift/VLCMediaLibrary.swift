//
//  VLCMediaLibrary.swift
//  VLCKit
//
//  VLCMediaLibrary - Media library for VLC
//  Note: libvlc_media_library_* functions are not available in this build
//  of MobileVLCKit. This class is kept as a stub for API compatibility.
//

import Foundation

/**
 VLCMediaLibrary - Media library singleton
 Note: The underlying libvlc media library API is not available in this build.
 */
public class VLCMediaLibrary: NSObject {

    public static let sharedMediaLibrary = VLCMediaLibrary()

    private override init() {
        super.init()
    }

    public var allMedia: VLCMediaList {
        return VLCMediaList()
    }
}
