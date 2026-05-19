import Foundation

// MARK: - Notifications
public extension VLCMedia {
    static var metaChangedNotification: NSNotificationName {
        NSNotificationName("VLCMediaMetaChangedNotification")
     }
}

// MARK: - Parse Options
public struct VLCMediaParseOptions: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /// Parse locally only (no network required)
    public static let local = VLCMediaParseOptions(rawValue: 1 << 0)
     /// Parse network resources (may require network)
    public static let network = VLCMediaParseOptions(rawValue: 1 << 1)
     /// Parse both local and network
    public static let localAndNetwork: VLCMediaParseOptions = [.local, .network]
     /// Fetch local metadata only
    public static let fetchLocal = VLCMediaParseOptions(rawValue: 1 << 2)
     /// Fetch network metadata
    public static let fetchNetwork = VLCMediaParseOptions(rawValue: 1 << 3)
     /// Fetch both
    public static let fetchLocalAndNetwork: VLCMediaParseOptions = [.fetchLocal, .fetchNetwork]
     /// Maximum parse depth
    public static let parseDepthMax = VLCMediaParseOptions(rawValue: 16)
}

// MARK: - Parsed Status
public enum VLCMediaParsedStatus: Int {
    case skipped = 0
    case failed = 1
    case done = 2
    case inProgress = 3
}

// MARK: - Core
public extension VLCMedia {
    static func media(url: URL) -> VLCMedia? {
        VLCMedia.mediaWithURL(url)
     }
    
    static func media(path: String) -> VLCMedia? {
        VLCMedia.mediaWithPath(path)
     }
    
    static func asNode(named name: String) -> VLCMedia? {
        VLCMedia.mediaAsNodeWithName(name)
     }
}

// MARK: - Convenience
extension VLCMedia {
     @objc public func parse() {
         parseWithOptions(.localAndNetwork)
      }
    
     @objc public func addSubitem(_ media: VLCMedia) -> VLCMedia? {
         addSubitem(media)
      }
    
     @objc public func parseWithOptions(_ options: VLCMediaParseOptions) {
         parseWithOptions(options.rawValue)
      }
}

// MARK: - Properties
extension VLCMedia {
     @objc public var url: URL? {
         if let uri = libvlc_media_get_uri(self), let url = URL(string: uri) {
             return url
          }
         return nil
      }
    
     @objc public var length: VLCTime {
         let duration = libvlc_media_get_duration(self)
         return VLCTime.timeWithNumber(duration)
      }
    
     @objc public var parsedStatus: VLCMediaParsedStatus {
         let raw = libvlc_media_get_parsed_status(self)
         return VLCMediaParsedStatus(rawValue: raw) ?? .skipped
      }
}
