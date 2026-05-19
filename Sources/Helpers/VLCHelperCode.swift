import Foundation

func toNSStr(_ str: UnsafePointer<CChar>?) -> String {
    return str != nil ? String(cString: str!) : ""
}

#if NDEBUG
func VKLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#else
func VKLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items.map { String(describing: $0) }.joined(separator: separator), terminator: terminator)
}
#endif
