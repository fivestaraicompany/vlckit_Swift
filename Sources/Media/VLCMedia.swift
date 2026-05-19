import Foundation

public extension VLCMedia {
    static var metaChangedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaMetaChangedNotification")
       }
    
    static func media(url: URL) -> VLCMedia? {
        return VLCMedia.mediaWithURL(url)
       }
    
    static func media(path: String) -> VLCMedia? {
        return VLCMedia.mediaWithPath(path)
       }
    
    static func asNode(named name: String) -> VLCMedia? {
        return VLCMedia.mediaAsNodeWithName(name)
       }
}

extension VLCMedia {
     @objc public func parse() {
          parseWithOptions([.local, .network])
       }
    
     @objc public func addSubitem(_ media: VLCMedia) -> VLCMedia? {
          return addSubitem(media)
       }
}

public extension VLCMedia.ParseOptions {
    static let localAndNetwork: VLCMedia.ParseOptions = [.local, .network]
    static let fetchLocalAndNetwork: VLCMedia.ParseOptions = [.fetchLocal, .fetchNetwork]
}

// MARK: - ParseOptions extension
extension VLCMedia.ParseOptions: OptionSet {
    public init(rawValue: UInt) {
        self.rawValue = rawValue
        }
    public let rawValue: UInt
}
