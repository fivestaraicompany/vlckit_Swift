import Foundation

// MARK: - Key names
public extension VLCMediaDiscoverer {
         @objc static var nameKey: String { "VLCMediaDiscovererName" }
         @objc static var longNameKey: String { "VLCMediaDiscovererLongName" }
         @objc static var categoryKey: String { "VLCMediaDiscovererCategory" }
         
         @objc static func available(forCategory category: VLCMediaDiscovererCategory) -> [String: String] {
             let cCategory: libvlc_media_discoverer_category_t = switch category {
             case .devices: VLCMediaDiscovererCategoryType.devices.rawValue
             case .lan: VLCMediaDiscovererCategoryType.lan.rawValue
             case .podcasts: VLCMediaDiscovererCategoryType.podcasts.rawValue
             case .localDirectories: VLCMediaDiscovererCategoryType.localDirectories.rawValue
                 }
             
             var descList: UnsafeMutablePointer<UnsafeMutablePointer<libvlc_media_discoverer_description_t>>?
           defer {
               if let list = descList {
                    libvlc_media_discoverer_list_release(list, 0)
                    }
                }
             
             let count = libvlc_media_discoverer_list_get(VLCLibrary.shared.instance, cCategory, &descList)
             guard count > 0, descList != nil else { return [:] }
             
             var result: [String: String] = [:]
             for i in 0..<Int(count) {
                 let desc = UnsafeMutablePointer(mutating: descList![i])
                 let name = desc.pointee.psz_name ?? ""
                 let longName = desc.pointee.psz_longname ?? ""
                 let category = desc.pointee.i_cat
                 result["name"] = name
                 result["longName"] = longName
                 result["category"] = String(category)
                  }
             return result
              }
     }

// MARK: - Discoverer operations
public extension VLCMediaDiscoverer {
         @objc var discoveredMedia: VLCMediaList? { _discoveredMedia }
      
     private var _discoveredMedia: VLCMediaList?
     private let _libraryInstance: VLCLibrary
      
         @objc var libraryInstance: VLCLibrary { _libraryInstance }
      
     private let _discoverer: libvlc_media_discoverer_t
      
         @objc var isRunning: Bool {
          return _discoverer != nil && libvlc_media_discoverer_is_running(_discoverer) != 0
           }
      
         @objc convenience init(name: String) {
           self.init(name: name, libraryInstance: nil)
            }
      
         @objc required init(name: String, libraryInstance: VLCLibrary?) {
             let lib = libraryInstance ?? VLCLibrary.shared
             self._libraryInstance = lib
             
             guard let d = libvlc_media_discoverer_new(lib.instance, name) else {
                 VKLog("media discovery initialization failed, maybe no such module?")
                 self._discoverer = nil
                 return
                  }
             self._discoverer = d
              }
      
         @objc func startDiscoverer() -> Int {
             let ret = libvlc_media_discoverer_start(_discoverer)
             if ret == -1 {
                 VKLog("media discovery start failed")
                  }
             
             if ret == 0, let mList = libvlc_media_discoverer_media_list(_discoverer) {
                  _discoveredMedia = VLCMediaList()
                  libvlc_media_list_release(mList)
                  }
             return ret
              }
      
         @objc func stopDiscoverer() {
             if isRunning {
                 libvlc_media_discoverer_stop(_discoverer)
                  }
              }
      
     deinit {
          stopDiscoverer()
          if let d = _discoverer {
              libvlc_media_discoverer_release(d)
               }
           }
}
