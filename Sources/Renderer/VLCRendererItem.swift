import Foundation

public extension VLCRendererItem {
       @objc var name: String { _name }
       @objc var type: String { _type }
       @objc var iconURI: String { _iconURI }
       @objc var flags: Int { _flags }
       @objc var canPlayAudio: Bool { (_flags & VLCRendererPlaysAudio.rawValue) != 0 }
       @objc var canPlayVideo: Bool { (_flags & VLCRendererPlaysVideo.rawValue) != 0 }
      
    private let _name: String
    private let _type: String
    private let _iconURI: String
    private let _flags: Int
      
       @objc convenience init(name: String, type: String, iconURI: String, flags: Int) {
           self.init(name: name, type: type, iconURI: iconURI, flags: flags)
          }
      
       @objc required init(name: String, type: String, iconURI: String, flags: Int) {
           self._name = name
           self._type = type
           self._iconURI = iconURI
           self._flags = flags
           super.init()
          }
}
