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
         _properties = properties.mutableCopy() as? [String: Any] ?? [:]
         _properties[VLCFilterParameterPropertyValueKey] = properties[VLCFilterParameterPropertyDefaultValueKey]?.copy()
        super.init()
       }

    public var value: Any? {
        return _properties[VLCFilterParameterPropertyValueKey]
       }

    public var defaultValue: Any? {
        return _properties[VLCFilterParameterPropertyDefaultValueKey]
       }

    public var minValue: Any? {
        return _properties[VLCFilterParameterPropertyMinValueKey]
       }

    public var maxValue: Any? {
        return _properties[VLCFilterParameterPropertyMaxValueKey]
       }

    public func isValueSetToDefault() -> Bool {
        let currentValue = (_properties[VLCFilterParameterPropertyValueKey] as? NSNumber)?.floatValue ?? 0.0
        let defaultValue = (_properties[VLCFilterParameterPropertyDefaultValueKey] as? NSNumber)?.floatValue ?? 0.0
        return currentValue == defaultValue
       }

    public var valueChangeAction: ((Any) -> Void)? {
        get {
            guard let action = _properties[VLCFilterParameterPropertyValueChangeActionKey] as? ((Any) -> Void) else {
                return nil
             }
            return action
          }
        set {
             _properties[VLCFilterParameterPropertyValueChangeActionKey] = newValue
          }
       }

    public override func setValue(_ value: Any) {
        guard let valueNumber = value as? NSNumber else {
            NSException(name: .unexpectedParameter, reason: "Can't call [value floatValue] from [VLCFilterParameter setValue:]", userInfo: nil).raise()
            return
         }

        let newValue = valueNumber.floatValue
        let currentValue = (_properties[VLCFilterParameterPropertyValueKey] as? NSNumber)?.floatValue ?? 0.0

        guard newValue != currentValue else { return }

        let maxValue = (_properties[VLCFilterParameterPropertyMaxValueKey] as? NSNumber)?.floatValue ?? 0.0
        let minValue = (_properties[VLCFilterParameterPropertyMinValueKey] as? NSNumber)?.floatValue ?? 0.0

        let clampedValue = newValue.clamped(to: minValue...maxValue)

         _properties[VLCFilterParameterPropertyValueKey] = NSNumber(value: clampedValue)

        if let action = _properties[VLCFilterParameterPropertyValueChangeActionKey] as? ((Any) -> Void) {
            action(self.value)
         }
       }
}

/**
 VLCFilter - Filter base class
 */
public final class VLCFilter: NSObject {

    public var name: String = ""
    public var enabled: Bool = false

      /**
     Create a new filter
       */
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

// MARK: - Extension

extension RangeReplaceableCollection where Index == Int {
    func clamped(to range: ClosedRange<Bound>) -> [Bound] {
        return map { min(max($0, range.lowerBound), range.upperBound) }
      }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
      }
}
