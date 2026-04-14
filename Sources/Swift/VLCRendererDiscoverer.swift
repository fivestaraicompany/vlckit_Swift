//
//  VLCRendererDiscoverer.swift
//  VLCKit
//
//  VLCRendererDiscoverer - Renderer discoverer
//

import Foundation

/**
 Protocol for renderer discoverer delegate
 */
public protocol VLCRendererDiscovererDelegate: AnyObject {
    func rendererDiscoverer(_ rendererDiscoverer: VLCRendererDiscoverer, itemAdded: VLCRendererItem)
    func rendererDiscoverer(_ rendererDiscoverer: VLCRendererDiscoverer, itemDeleted: VLCRendererItem)
}

/**
 VLCRendererDiscoverer - Renderer discoverer for VLC
 */
public class VLCRendererDiscoverer: NSObject {

    public weak var delegate: (any VLCRendererDiscovererDelegate)? = nil

    public private(set) var name: String = ""
    public private(set) var state: VLCRendererDiscovererState = .unknown

    private var _rendererDiscoverer: OpaquePointer? = nil
    private var _rendererItems: [VLCRendererItem] = []
    private var _eventsHandler: VLCEventsHandler?

    /**
     Create a new renderer discoverer

     - Parameter name: The name of the renderer discoverer
     - Returns: A new renderer discoverer instance
     */
    public convenience init?(name: String) {
        self.init()

        NSAssert(!name.isEmpty, "VLCRendererDiscoverer: name is NULL")

         name = name
         _rendererDiscoverer = libvlc_renderer_discoverer_new(VLCLibrary.sharedLibrary.instance, name)

        if _rendererDiscoverer == nil {
            NSAssert(false, "Failed to create renderer with name \(name)")
            return nil
        }

         _rendererItems = []

        if let em = libvlc_renderer_discoverer_event_manager(_rendererDiscoverer) {
             _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)
            let userData = Unmanaged.passRetained(_eventsHandler!).toOpaque()
            libvlc_event_attach(em, libvlc_RendererDiscovererItemAdded, HandleRendererDiscovererItemAdded, userData)
            libvlc_event_attach(em, libvlc_RendererDiscovererItemDeleted, HandleRendererDiscovererItemDeleted, userData)
        }
     }

    deinit {
        if let em = libvlc_renderer_discoverer_event_manager(_rendererDiscoverer) {
            if let userData = _eventsHandler.map({ Unmanaged.passRetained($0).toOpaque() }) {
                libvlc_event_detach(em, libvlc_RendererDiscovererItemAdded, HandleRendererDiscovererItemAdded, userData)
                libvlc_event_detach(em, libvlc_RendererDiscovererItemDeleted, HandleRendererDiscovererItemDeleted, userData)
              }
          }

        if let rendererDiscoverer = _rendererDiscoverer {
            libvlc_renderer_discoverer_release(rendererDiscoverer)
         }
     }

    public override var description: String {
        return "\(type(of: self)) - name: \(name) number of renderers: \(items.count)"
      }

    public func start() -> Bool {
        return libvlc_renderer_discoverer_start(_rendererDiscoverer) == 0
      }

    public func stop() {
        libvlc_renderer_discoverer_stop(_rendererDiscoverer)
      }

    public static func list() -> [VLCRendererDiscovererDescription] {
        var pp_services: UnsafeMutablePointer<UnsafeMutablePointer<libvlc_rd_description_t>?>? = nil
        let i_nb_services = libvlc_renderer_discoverer_list_get(VLCLibrary.sharedLibrary.instance, &pp_services)

        guard i_nb_services > 0 else { return [] }

        var list: [VLCRendererDiscovererDescription] = []
        for i in 0..<i_nb_services {
            guard let service = pp_services?.advanced(index: Int(i)) else { continue }
            guard let psz_name = service.pointee.psz_name else { continue }
            guard let psz_longname = service.pointee.psz_longname else { continue }

            list.append(VLCRendererDiscovererDescription(name: String(cString: psz_name),
                                                           longName: String(cString: psz_longname)))
         }

        libvlc_renderer_discoverer_list_release(pp_services, i_nb_services)
        return list
      }

    public var items: [VLCRendererItem] {
        return _rendererItems
      }

    private func discoveredItemsContainItem(_ item: VLCRendererItem) -> VLCRendererItem? {
        for rendererItem in _rendererItems {
            if rendererItem.name == item.name && rendererItem.type == item.type {
                return rendererItem
             }
         }
        return nil
      }

    private func itemAdded(_ item: VLCRendererItem) {
        let rendererItem = discoveredItemsContainItem(item)

        if rendererItem == nil {
             _rendererItems.append(item)
             delegate?.rendererDiscoverer(self, itemAdded: item)
         }
      }

    private func itemDeleted(_ item: VLCRendererItem) {
        let rendererItem = discoveredItemsContainItem(item)

        if rendererItem != nil {
             _rendererItems.removeAll { $0 === item }
             delegate?.rendererDiscoverer(self, itemDeleted: item)
         }
      }
}

/**
 VLCRendererDiscovererDescription - Description of a renderer discoverer
 */
public class VLCRendererDiscovererDescription: NSObject {

    public private(set) var name: String
    public private(set) var longName: String

     /**
     Create a new renderer discoverer description

      - Parameters:
        - name: The name
        - longName: The long name
      - Returns: A new renderer discoverer description instance
      */
    public init(name: String, longName: String) {
         NSAssert(!name.isEmpty, "VLCRendererDiscovererDescription: name is NULL")
         NSAssert(!longName.isEmpty, "VLCRendererDiscovererDescription: longName is NULL")

        self.name = name
        self.longName = longName

        super.init()
      }

    public override var description: String {
        return "\(type(of: self)) - name: \(name)"
      }
}

// MARK: - Event Handlers

private func HandleRendererDiscovererItemAdded(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let renderer = VLCRendererItem(rendererItem: event.u.renderer_discoverer_item_added.item)
    guard let renderer = renderer else { return }

    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let rendererDiscoverer = object as! VLCRendererDiscoverer
        rendererDiscoverer.itemAdded(renderer)
      }
}

private func HandleRendererDiscovererItemDeleted(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    let renderer = VLCRendererItem(rendererItem: event.u.renderer_discoverer_item_deleted.item)
    guard let renderer = renderer else { return }

    let eventsHandler = opaque.map { Unmanaged<VLCEventsHandler>.from($0).takeUnretainedValue() } ?? return

    eventsHandler.handleEvent { object in
        let rendererDiscoverer = object as! VLCRendererDiscoverer
        rendererDiscoverer.itemDeleted(renderer)
      }
}
