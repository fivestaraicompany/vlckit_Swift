//
//  VLCMediaLibrary.swift
//  VLCKit
//
//  VLCMediaLibrary - Media library for VLC
//

import Foundation

/**
 VLCMediaLibrary - Media library singleton
 */
public class VLCMediaLibrary: NSObject {

    public static let sharedMediaLibrary = VLCMediaLibrary()

    private var _mediaList: OpaquePointer?
    private var _allMedia: VLCMediaList?
    private var _once: dispatch_once_t = 0

     /**
     Create a new media library instance
       */
    private override init() {
        super.init()
         _mediaList = libvlc_media_library_new(VLCLibrary.sharedLibrary.instance)
        libvlc_media_library_load(_mediaList)
     }

    deinit {
        libvlc_media_library_release(_mediaList)
         _mediaList = nil
     }

    public var allMedia: VLCMediaList {
        dispatch_once(&_once) {
            let mediaList = libvlc_media_library_media_list(_mediaList)
            if mediaList != nil {
                 _allMedia = VLCMediaList()
                 _allMedia?._mediaList = mediaList
                 libvlc_media_list_retain(mediaList)
             }
         }
        return _allMedia!
     }
}
