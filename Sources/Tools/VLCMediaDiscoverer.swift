import Foundation

public extension VLCMediaDiscoverer {
       @objc static var nameKey: String { "VLCMediaDiscovererName" }
       @objc static var longNameKey: String { "VLCMediaDiscovererLongName" }
       @objc static var categoryKey: String { "VLCMediaDiscovererCategory" }
      
       @objc static func available(forCategory category: VLCMediaDiscovererCategory) -> [String: String] {
           let cCategory: libvlc_media_discoverer_category_t = switch category {
           case .devices: .devices
           case .lan: .lan
           case .podcasts: .podcasts
           case .localDirectories: .localDirectories
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
           for i in 0..<count {
               let desc = UnsafeMutablePointer(mutating: descList![i])
               let name = desc.pointee.psz_name ?? ""
               let longName = desc.pointee.psz_longname ?? ""
               let category = Int(desc.pointee.i_cat)
               result["name"] = name
               result["longName"] = longName
               result["category"] = String(category)
               }
           return result
           }
      
       @objc var discoveredMedia: VLCMediaList? { _discoveredMedia }
      
    private var _discoveredMedia: VLCMediaList?
    private let _libraryInstance: VLCLibrary
      
       @objc var libraryInstance: VLCLibrary { _libraryInstance }
      
    private let discoverer: libvlc_media_discoverer_t
      
       @objc var isRunning: Bool {
           return libvlc_media_discoverer_is_running(discoverer) != 0
           }
      
       @objc convenience init(name: String) {
           self.init(name: name, libraryInstance: nil)
           }
      
       @objc required init(name: String, libraryInstance: VLCLibrary?) {
           let lib = libraryInstance ?? VLCLibrary.shared
           self._libraryInstance = lib
          
           guard let d = libvlc_media_discoverer_new(lib.instance, name) else {
               VKLog("media discovery initialization failed, maybe no such module?")
               self.discoverer = nil
               return
               }
           self.discoverer = d
           }
      
       @objc func startDiscoverer() -> Int {
           let ret = libvlc_media_discoverer_start(discoverer)
           if ret == -1 {
               VKLog("media discovery start failed")
               }
          
           if ret == 0, let mList = libvlc_media_discoverer_media_list(discoverer) {
                _discoveredMedia = VLCMediaList(mediaListWithLibVLCMediaList: mList)
               libvlc_media_list_release(mList)
               }
           return ret
           }
      
       @objc func stopDiscoverer() {
           if isRunning {
               libvlc_media_discoverer_stop(discoverer)
               }
           }
      
      deinit {
          stopDiscoverer()
          if let d = discoverer {
              libvlc_media_discoverer_release(d)
              }
           }
}

// MARK: - Category typealias
public typealias VLCMediaDiscovererCategory = VLCMediaDiscovererCategoryType
