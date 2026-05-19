import Foundation

// MARK: - Discoverer description
extension VLCRendererDiscovererDescription {
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

// MARK: - Discoverer list
extension VLCRendererDiscoverer {
         @objc static func list() -> [VLCRendererDiscovererDescription] {
           var descList: UnsafeMutablePointer<UnsafeMutablePointer<lib_rd_description_t>>?
         defer {
             if let list = descList {
                  libvlc_renderer_discoverer_list_release(list, 0)
                  }
              }
          
           let count = libvlc_renderer_discoverer_list_get(VLCLibrary.shared.instance, &descList)
           guard count > 0, descList != nil else { return [] }
          
           var descriptions: [VLCRendererDiscovererDescription] = []
           for i in 0..<Int(count) {
               let desc = UnsafeMutablePointer(mutating: descList![i])
               let name = desc.pointee.psz_name ?? ""
               let longName = desc.pointee.psz_longname ?? ""
               descriptions.append(VLCRendererDiscovererDescription(name: name, longName: longName))
                }
           return descriptions
           }
}

// MARK: - Discoverer operations
extension VLCRendererDiscoverer {
         @objc var renderers: [VLCRendererItem] {
           var items: [VLCRendererItem] = []
           var item = libvlc_renderer_discoverer_next(self)
           while item != nil {
               // RendererItem would be constructed from libvlc renderer item
               // This requires ObjC bridge implementation
               item = libvlc_renderer_item_next(item)
            }
           return items
            }
        
         @objc var name: String { _name }
        
       private let _name: String
        
             @objc func start() -> Bool {
           return libvlc_renderer_discoverer_start(self) == 0
            }
        
             @objc func stop() {
           libvlc_renderer_discoverer_stop(self)
            }
}
