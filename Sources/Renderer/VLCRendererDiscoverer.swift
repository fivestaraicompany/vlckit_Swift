import Foundation

public extension VLCRendererDiscoverer {
       @objc var renderers: [VLCRendererItem] {
           return _renderers ?? []
          }
      
    private var _renderers: [VLCRendererItem]?
      
       @objc var name: String { _name }
      
    private let _name: String
      
       @objc func start() -> Bool {
           return libvlc_renderer_discoverer_start(rendererDiscoverer) == 0
          }
      
       @objc func stop() {
           libvlc_renderer_discoverer_stop(rendererDiscoverer)
          }
}

public extension VLCRendererDiscovererDescription {
       @objc var name: String { _name }
       @objc var longName: String { _longName }
      
    private let _name: String
    private let _longName: String
      
       @objc required init(name: String, longName: String) {
           self._name = name
           self._longName = longName
           super.init()
          }
}

public extension VLCRendererDiscoverer {
       @objc static func list() -> [VLCRendererDiscovererDescription] {
           var descList: UnsafeMutablePointer<UnsafeMutablePointer<libvlc_rd_description_t>>?
          defer {
              if let list = descList {
                   libvlc_renderer_discoverer_list_release(list, 0)
                  }
              }
          
           let count = libvlc_renderer_discoverer_list_get(VLCLibrary.shared.instance, &descList)
           guard count > 0, descList != nil else { return [] }
          
           var descriptions: [VLCRendererDiscovererDescription] = []
           for i in 0..<count {
               let desc = UnsafeMutablePointer(mutating: descList![i])
               let name = desc.pointee.psz_name ?? ""
               let longName = desc.pointee.psz_longname ?? ""
               descriptions.append(VLCRendererDiscovererDescription(name: name, longName: longName))
               }
           return descriptions
          }
}
