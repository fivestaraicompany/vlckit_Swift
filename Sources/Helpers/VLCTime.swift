import Foundation

public extension VLCTime {
    static func null() -> VLCTime {
        VLCTime.nullTime()
    }
    
    static func from(_ aNumber: NSNumber?) -> VLCTime {
        VLCTime.timeWithNumber(aNumber)
    }
    
    static func from(_ aInt: Int32) -> VLCTime {
        VLCTime.timeWithInt(aInt)
    }
    
    static func clock() -> Int64 {
        VLCTime.clock()
    }
    
    static func delay(_ ts: Int64) -> Int64 {
        VLCTime.delay(ts)
    }
}

extension VLCTime: NSCopying {
    public func copy(with region: NSZone? = nil) -> Any {
        if let value = value {
            return VLCTime.timeWithNumber(value)
        }
        return VLCTime.nullTime()
    }
}

extension VLCTime: NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    
    public func encode(with coder: NSCoder) {
        coder.encode(value, forKey: "value")
    }
    
    public required init?(coder: NSCoder) {
        if let num = coder.decodeObject(of: NSNumber.self, forKey: "value") as? NSNumber {
            self.init(number: num)
        } else {
            self.init(int: 0)
        }
    }
}
