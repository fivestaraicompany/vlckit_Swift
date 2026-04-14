//
//  VLCFilter.swift
//  VLCKit
//
//  VLCFilter - Filter base class
//

import Foundation

/**
 VLCFilterParameter - Filter parameter
 */
public final class VLCFilterParameter: NSObject {

    private var _properties: [String: Any] = [:]

    public static func create(withProperties properties: [String: Any]) -> VLCFilterParameter {
        return VLCFilterParameter(withProperties: properties)
    }

    public override init() {
        super.init()
    }

    public init(withProperties properties: [String: Any]) {
        _properties = properties
        _properties[kVLCFilterParameterPropertyValueKey] = properties[kVLCFilterParameterPropertyDefaultValueKey]
        super.init()
    }

    public var value: Any? {
        return _properties[kVLCFilterParameterPropertyValueKey]
    }

    public var defaultValue: Any? {
        return _properties[kVLCFilterParameterPropertyDefaultValueKey]
    }

    public var minValue: Any? {
        return _properties[kVLCFilterParameterPropertyMinValueKey]
    }

    public var maxValue: Any? {
        return _properties[kVLCFilterParameterPropertyMaxValueKey]
    }

    public func isValueSetToDefault() -> Bool {
        let currentValue = (_properties[kVLCFilterParameterPropertyValueKey] as? NSNumber)?.floatValue ?? 0.0
        let defValue = (_properties[kVLCFilterParameterPropertyDefaultValueKey] as? NSNumber)?.floatValue ?? 0.0
        return currentValue == defValue
    }

    public var valueChangeAction: ((Any) -> Void)? {
        get {
            return _properties[kVLCFilterParameterPropertyValueChangeActionKey] as? ((Any) -> Void)
        }
        set {
            _properties[kVLCFilterParameterPropertyValueChangeActionKey] = newValue
        }
    }

    public func setValue(_ value: NSNumber) {
        let newValue = value.floatValue
        let currentValue = (_properties[kVLCFilterParameterPropertyValueKey] as? NSNumber)?.floatValue ?? 0.0

        guard newValue != currentValue else { return }

        let maxVal = (_properties[kVLCFilterParameterPropertyMaxValueKey] as? NSNumber)?.floatValue ?? Float.greatestFiniteMagnitude
        let minVal = (_properties[kVLCFilterParameterPropertyMinValueKey] as? NSNumber)?.floatValue ?? -Float.greatestFiniteMagnitude

        let clampedValue = min(max(newValue, minVal), maxVal)

        _properties[kVLCFilterParameterPropertyValueKey] = NSNumber(value: clampedValue)

        if let action = _properties[kVLCFilterParameterPropertyValueChangeActionKey] as? ((Any) -> Void) {
            action(NSNumber(value: clampedValue))
        }
    }
}

/**
 VLCFilter - Filter base class
 */
public class VLCFilter: NSObject {

    public var name: String = ""
    public var enabled: Bool = false

    public override init() {
        super.init()
    }

    public init(name: String, enabled: Bool) {
        self.name = name
        self.enabled = enabled
        super.init()
    }

    public func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    public func reset() {
        enabled = false
    }
}

// MARK: - Constants

public let kVLCFilterParameterPropertyLibVLCFilterOptionKey = "LibVLCFilterOption"
public let kVLCFilterParameterPropertyParameterKey = "ParameterKey"
public let kVLCFilterParameterPropertyDefaultValueKey = "DefaultValue"
public let kVLCFilterParameterPropertyValueKey = "Value"
public let kVLCFilterParameterPropertyMinValueKey = "MinValue"
public let kVLCFilterParameterPropertyMaxValueKey = "MaxValue"
public let kVLCFilterParameterPropertyValueChangeActionKey = "ValueChangeAction"
