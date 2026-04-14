//
//  VLCTime.swift
//  VLCKit
//
//  VLCTime - A time object for VLC media playback
//

import Foundation

/**
 A time object for VLC media playback.
 */
public final class VLCTime: NSObject {

    private var _value: NSNumber?

    /// The current time value as NSNumber (in milliseconds)
    public var value: NSNumber? {
        return _value
    }

    /// The current time value as NSNumber (deprecated, use `value` instead)
    @available(*, deprecated, message: "Use value instead")
    public var numberValue: NSNumber? {
        return _value
    }

    /// The current time value as a formatted string (e.g., "02:30")
    public var stringValue: String {
        if let val = _value {
            let duration = val.int64Value
            if duration == Int64.max || duration == Int64.min {
                return "--:--"
            }
            let positiveDuration = abs(duration / 1000)
            let hours = Int(positiveDuration) / 3600
            let mins = (Int(positiveDuration) / 60) % 60
            let seconds = Int(positiveDuration) % 60

            let sign = duration < 0 ? "-" : ""
            if positiveDuration >= 3600 {
                return String(format: "%@%01d:%02d:%02d", sign, hours, mins, seconds)
            } else {
                return String(format: "%@%02d:%02d", sign, mins, seconds)
            }
        } else {
            return "--:--"
        }
    }

    /// The current time value as a verbose string
    public var verboseStringValue: String {
        guard let val = _value else {
            return ""
        }

        let duration = val.int64Value / 1000
        let positiveDuration = abs(duration)
        let hours = Int(positiveDuration) / 3600
        let mins = (Int(positiveDuration) / 60) % 60
        let seconds = Int(positiveDuration) % 60
        let remaining = duration < 0

        if hours > 0 {
            let format = remaining ? NSLocalizedString("%ld hours %ld minutes remaining", comment: "") : NSLocalizedString("%ld hours %ld minutes", comment: "")
            return String(format: format, hours, mins)
        }
        if mins > 5 {
            let format = remaining ? NSLocalizedString("%ld minutes remaining", comment: "") : NSLocalizedString("%ld minutes", comment: "")
            return String(format: format, mins)
        }
        if mins > 0 {
            let format = remaining ? NSLocalizedString("%ld minutes %ld seconds remaining", comment: "") : NSLocalizedString("%ld minutes %ld seconds", comment: "")
            return String(format: format, mins, seconds)
        }
        let format = remaining ? NSLocalizedString("%ld seconds remaining", comment: "") : NSLocalizedString("%ld seconds", comment: "")
        return String(format: format, seconds)
    }

    /// The current time value as a minutes string
    public var minuteStringValue: String {
        guard let val = _value else {
            return ""
        }
        let positiveDuration = abs(val.int64Value)
        let minutes = Int(positiveDuration) / 60000
        return String(format: "%d", minutes)
    }

    /// The current time value as an integer
    public var intValue: Int {
        guard let val = _value else {
            return 0
        }
        return val.intValue
    }

    /// Create a null/empty time
    public static func nullTime() -> VLCTime {
        return VLCTime(timeWithNumber: nil)
    }

    /// Create a time from a number
    public static func timeWithNumber(_ aNumber: NSNumber?) -> VLCTime {
        return VLCTime(timeWithNumber: aNumber)
    }

    /// Create a time from an integer
    public static func timeWithInt(_ aInt: Int) -> VLCTime {
        return VLCTime(timeWithInt: aInt)
    }

    /// Initialize a time from a number
    public init(timeWithNumber aNumber: NSNumber?) {
        self._value = aNumber
        super.init()
    }

    /// Initialize a time from an integer
    public init(timeWithInt aInt: Int) {
        self._value = NSNumber(value: aInt)
        super.init()
    }

    /// Initialize a time from an Int64
    public init(timeWithInt aInt: Int64) {
        self._value = NSNumber(value: aInt)
        super.init()
    }

    /// Compare this VLCTime against another
    public func compare(_ aTime: VLCTime) -> ComparisonResult {
        let a = _value?.intValue ?? 0
        let b = aTime._value?.intValue ?? 0

        if a > b {
            return .orderedDescending
        } else if a < b {
            return .orderedAscending
        } else {
            return .orderedSame
        }
    }

    /// Check equality with another object
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VLCTime else {
            return false
        }
        return self.stringValue == other.stringValue
    }

    /// Hash value
    public override var hash: Int {
        return self.stringValue.hash
    }

    /// Description
    public override var description: String {
        return self.stringValue
    }
}
