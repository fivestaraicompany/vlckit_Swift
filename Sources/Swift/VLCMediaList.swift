//
//  VLCMediaList.swift
//  VLCKit
//
//  VLCMediaList - Media list for VLC playback
//

import Foundation
import CLibVLC

/**
 Notification name for item added
 */
public extension Notification.Name {
    static let VLCMediaListItemAdded = Notification.Name("VLCMediaListItemAdded")
    static let VLCMediaListItemDeleted = Notification.Name("VLCMediaListItemDeleted")
}

/**
 Protocol for media list delegate
 */
public protocol VLCMediaListDelegate: AnyObject {
    func mediaList(_ mediaList: VLCMediaList, mediaAdded: VLCMedia, atIndex: Int)
    func mediaList(_ mediaList: VLCMediaList, mediaRemovedAtIndex: Int)
}

/**
 VLCMediaList - Media list for VLC playback
 */
public class VLCMediaList: NSObject {

    public weak var delegate: (any VLCMediaListDelegate)?

    private var _mediaList: OpaquePointer?
    var mediaObjects: [VLCMedia] = []
    private var _serialMediaObjectsQueue: DispatchQueue

    /**
     Create a new media list
     */
    public override init() {
        _serialMediaObjectsQueue = DispatchQueue(label: "org.videolan.serialMediaObjectsQueue")
        super.init()
        _mediaList = libvlc_media_list_new(VLCLibrary.sharedLibrary.instance)
    }

    /**
     Initialize with an array of media
     */
    public convenience init(mediaArray: [VLCMedia]) {
        self.init()
        for media in mediaArray {
            addMedia(media)
        }
    }

    /**
     Initialize with a libvlc media list
     */
    convenience init(libVLCMediaList: OpaquePointer) {
        self.init()
        if _mediaList != nil {
            libvlc_media_list_release(_mediaList!)
        }
        _mediaList = libVLCMediaList
        libvlc_media_list_retain(libVLCMediaList)
    }

    deinit {
        delegate = nil
        if let mediaList = _mediaList {
            libvlc_media_list_release(mediaList)
        }
    }

    public override var description: String {
        var content = ""
        for (i, media) in mediaObjects.enumerated() {
            content.append("\(i): \(media)\n")
        }
        return "<\(type(of: self)) {\n\(content)}"
    }

    public func lock() {
        libvlc_media_list_lock(_mediaList)
    }

    public func unlock() {
        libvlc_media_list_unlock(_mediaList)
    }

    @discardableResult
    public func addMedia(_ media: VLCMedia) -> Int {
        let index = count
        insertMedia(media, atIndex: index)
        return index
    }

    public func insertMedia(_ media: VLCMedia, atIndex index: Int) {
        _serialMediaObjectsQueue.sync {
            mediaObjects.insert(media, at: index)
        }

        if let mediaList = _mediaList, let mediaDescriptor = media.libVLCMediaDescriptor {
            libvlc_media_list_insert_media(mediaList, mediaDescriptor, Int32(index))
        }
    }

    @discardableResult
    public func removeMedia(atIndex index: Int) -> Bool {
        var ok = true

        _serialMediaObjectsQueue.sync {
            if index >= mediaObjects.count {
                ok = false
                return
            }
            mediaObjects.remove(at: index)
        }

        if let mediaList = _mediaList {
            libvlc_media_list_remove_index(mediaList, Int32(index))
        }

        return ok
    }

    public func media(atIndex index: Int) -> VLCMedia? {
        var media: VLCMedia?
        _serialMediaObjectsQueue.sync {
            media = index < mediaObjects.count ? mediaObjects[index] : nil
        }
        return media
    }

    public func indexOfMedia(_ media: VLCMedia) -> Int {
        return mediaObjects.firstIndex(of: media) ?? -1
    }

    public var count: Int {
        var result = 0
        _serialMediaObjectsQueue.sync {
            result = mediaObjects.count
        }
        return result
    }

    public var isReadOnly: Bool {
        guard let mediaList = _mediaList else { return false }
        return libvlc_media_list_is_readonly(mediaList) != 0
    }
}
