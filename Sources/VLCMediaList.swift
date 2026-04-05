//
//  VLCMediaList.swift
//  VLCKit
//
//  VLCMediaList - Media list for VLC playback
//

import Foundation

/**
 Notification name for item added
 */
public let VLCMediaListItemAdded = "VLCMediaListItemAdded"

/**
 Notification name for item deleted
 */
public let VLCMediaListItemDeleted = "VLCMediaListItemDeleted"

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

    public weak var delegate: (any VLCMediaListDelegate)? = nil

    private var _mediaList: OpaquePointer?
    private var _mediaObjects: [VLCMedia] = []
    private var _serialMediaObjectsQueue: DispatchQueue?
    private var _eventsHandler: VLCEventsHandler?

    /**
     Create a new media list
     */
    public override init() {
        super.init()
        _mediaList = libvlc_media_list_new(VLCLibrary.sharedLibrary.instance)
        _mediaObjects = []
        _serialMediaObjectsQueue = DispatchQueue(label: "org.videolan.serialMediaObjectsQueue", attributes: .concurrent)
        initInternalMediaList()
    }

    /**
     Initialize with an array of media

     - Parameter array: Array of media objects
     - Returns: A new media list instance
     */
    public convenience init(mediaArray: [VLCMedia]) {
        self.init()
        for media in mediaArray {
            addMedia(media)
        }
    }

    deinit {
        if let em = libvlc_media_list_event_manager(_mediaList) {
            if let userData = _eventsHandler.map({ Unmanaged.passRetained($0).toOpaque() }) {
                libvlc_event_detach(em, libvlc_MediaListItemDeleted, HandleMediaListItemDeleted, userData)
                libvlc_event_detach(em, libvlc_MediaListItemAdded, HandleMediaListItemAdded, userData)
            }
        }

        delegate = nil

        if let mediaList = _mediaList {
            libvlc_media_list_release(mediaList)
        }
    }

    public override var description: String {
        var content = ""
        for (i, media) in _mediaObjects.enumerated() {
            content.append("\(i): \(media)\n")
        }
        return "<\(type(of: self)) \(self) {\n\(content)}"
    }

    public func lock() {
        libvlc_media_list_lock(_mediaList)
    }

    public func unlock() {
        libvlc_media_list_unlock(_mediaList)
    }

    public func addMedia(_ media: VLCMedia) -> Int {
        let index = count
        insertMedia(media, atIndex: index)
        return index
    }

    public func insertMedia(_ media: VLCMedia, atIndex index: Int) {
        _serialMediaObjectsQueue?.async {
            _mediaObjects.insert(media, at: index)
        }

        if let mediaList = _mediaList, let mediaDescriptor = media.libVLCMediaDescriptor {
            libvlc_media_list_insert_media(mediaList, mediaDescriptor, index)
        }
    }

    public func removeMedia(atIndex index: Int) -> Bool {
        var ok = true

        _serialMediaObjectsQueue?.async {
            if index >= _mediaObjects.count {
                ok = false
                return
            }
            _mediaObjects.remove(at: index)
        }

        if let mediaList = _mediaList {
            libvlc_media_list_remove_index(mediaList, index)
        }

        return ok
    }

    public func media(atIndex index: Int) -> VLCMedia? {
        var media: VLCMedia?
        _serialMediaObjectsQueue?.async {
            media = index < _mediaObjects.count ? _mediaObjects[index] : nil
        }
        return media
    }

    public func indexOfMedia(_ media: VLCMedia) -> Int {
        return _mediaObjects.firstIndex(of: media) ?? -1
    }

    public var count: Int {
        var count = 0
        _serialMediaObjectsQueue?.async {
            count = _mediaObjects.count
        }
        return count
    }

    public var isReadOnly: Bool {
        guard let mediaList = _mediaList else { return false }
        return libvlc_media_list_is_readonly(mediaList) != 0
    }

    private func initInternalMediaList() {
        guard let mediaList = _mediaList else { return }

        let eventsManager = libvlc_media_list_event_manager(mediaList)
        guard let eventsManager = eventsManager else { return }

        _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)
        let userData = Unmanaged.passRetained(_eventsHandler!).toOpaque()

        _serialMediaObjectsQueue?.async {
            libvlc_event_attach(eventsManager, libvlc_MediaListItemAdded, HandleMediaListItemAdded, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaListItemDeleted, HandleMediaListItemDeleted, userData)
        }
    }
}

// MARK: - Event Handlers

private func HandleMediaListItemAdded(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let item = event.u.media_list_item_added.item else { return }

    let addedMedia = VLCMedia(libVLCMediaDescriptor: item)
    guard let media = addedMedia else { return }

    let index = Int(event.u.media_list_item_added.index)

    guard let eventsHandler = opaque.map({ Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let mediaList = object as! VLCMediaList

        let notification = Notification(name: VLCMediaListItemAdded, object: mediaList, userInfo: ["index": index])
        NotificationCenter.default.post(notification)

        mediaList.delegate?.mediaList(mediaList, mediaAdded: media, atIndex: index)
    }
}

private func HandleMediaListItemDeleted(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let item = event.u.media_list_item_added.item else { return }

    let removedMedia = VLCMedia(libVLCMediaDescriptor: item)
    guard let media = removedMedia else { return }

    let index = Int(event.u.media_list_item_deleted.index)

    guard let eventsHandler = opaque.map({ Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let mediaList = object as! VLCMediaList

        let notification = Notification(name: VLCMediaListItemDeleted, object: mediaList, userInfo: ["index": index])
        NotificationCenter.default.post(notification)

        mediaList.delegate?.mediaList(mediaList, mediaRemovedAtIndex: index)
    }
}
