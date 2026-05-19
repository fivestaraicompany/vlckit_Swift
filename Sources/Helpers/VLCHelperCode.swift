import Foundation

     @objc public func toNSStr(_ str: UnsafePointer<CChar>?) -> String {
     return str != nil ? String(cString: str!) : ""
     }

     @objc public func VKLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
     #if NDEBUG
          // No-op in release
     #else
      print(items.map { String(describing: $0) }.joined(separator: separator), terminator: terminator)
     #endif
     }
