import Foundation

// VLCMediaMetaData extensions to provide Swift-friendly accessors
extension VLCMedia.MetaData {
    var cachedValue: NSDictionary? {
        return performSelector(Selector(("metaCache")))?.takeUnretainedValue() as? NSDictionary
        }
    
    func cacheValue(forKey key: libvlc_meta_t) -> Any? {
        return perform(Selector(("cacheValueForKey:")), with: NSNumber(value: key.rawValue))?.takeUnretainedValue()
        }
    
    func setMetadata(_ value: String?, forKey key: libvlc_meta_t) {
        let str = value ?? ""
        _ = perform(Selector(("setMetadata:forKey:")), with: str, with: NSNumber(value: key.rawValue))
        }
}
