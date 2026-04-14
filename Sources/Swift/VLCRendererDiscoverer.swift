//
//  VLCRendererDiscoverer.swift
//  VLCKit
//
//  VLCRendererDiscoverer - Renderer discoverer
//

import Foundation
import CLibVLC

/**
 Renderer discoverer state
 */
public enum VLCRendererDiscovererState: Int {
    case unknown = 0
    case started
    case stopped
}

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

    public weak var delegate: (any VLCRendererDiscovererDelegate)?

    public private(set) var name: String = ""
    public private(set) var state: VLCRendererDiscovererState = .unknown

    private var _rendererDiscoverer: OpaquePointer?
    private var _rendererItems: [VLCRendererItem] = []

    public init?(discovererName: String) {
        super.init()

        guard !discovererName.isEmpty else { return nil }

        self.name = discovererName
        _rendererDiscoverer = libvlc_renderer_discoverer_new(VLCLibrary.sharedLibrary.instance, discovererName)

        guard _rendererDiscoverer != nil else { return nil }
    }

    deinit {
        if let rendererDiscoverer = _rendererDiscoverer {
            libvlc_renderer_discoverer_release(rendererDiscoverer)
        }
    }

    public override var description: String {
        return "\(Swift.type(of: self)) - name: \(name) number of renderers: \(items.count)"
    }

    public func start() -> Bool {
        guard let rd = _rendererDiscoverer else { return false }
        let result = libvlc_renderer_discoverer_start(rd) == 0
        if result { state = .started }
        return result
    }

    public func stop() {
        guard let rd = _rendererDiscoverer else { return }
        libvlc_renderer_discoverer_stop(rd)
        state = .stopped
    }

    public static func list() -> [VLCRendererDiscovererDescription] {
        var pp_services: UnsafeMutablePointer<UnsafeMutablePointer<libvlc_rd_description_t>?>?
        let count = libvlc_renderer_discoverer_list_get(VLCLibrary.sharedLibrary.instance, &pp_services)

        guard count > 0, let services = pp_services else { return [] }

        var descriptions: [VLCRendererDiscovererDescription] = []
        for i in 0..<Int(count) {
            guard let service = services[i] else { continue }
            let name = service.pointee.psz_name.map { String(cString: $0) } ?? ""
            let longName = service.pointee.psz_longname.map { String(cString: $0) } ?? ""
            if !name.isEmpty {
                descriptions.append(VLCRendererDiscovererDescription(name: name, longName: longName))
            }
        }

        libvlc_renderer_discoverer_list_release(pp_services, count)
        return descriptions
    }

    public var items: [VLCRendererItem] {
        return _rendererItems
    }

    func itemAdded(_ item: VLCRendererItem) {
        let existing = _rendererItems.first { $0.name == item.name && $0.type == item.type }
        if existing == nil {
            _rendererItems.append(item)
            delegate?.rendererDiscoverer(self, itemAdded: item)
        }
    }

    func itemDeleted(_ item: VLCRendererItem) {
        if let index = _rendererItems.firstIndex(where: { $0.name == item.name && $0.type == item.type }) {
            _rendererItems.remove(at: index)
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

    public init(name: String, longName: String) {
        self.name = name
        self.longName = longName
        super.init()
    }

    public override var description: String {
        return "\(Swift.type(of: self)) - name: \(name)"
    }
}
