import Foundation

// MARK: - Filter parameter keys
public let kVLCFilterParameterPropertyLibVLCFilterOptionKey = "LibVLCFilterOption"
public let kVLCFilterParameterPropertyParameterKey = "ParameterKey"
public let kVLCFilterParameterPropertyDefaultValueKey = "DefaultValue"
public let kVLCFilterParameterPropertyMinValueKey = "MinValue"
public let kVLCFilterParameterPropertyMaxValueKey = "MaxValue"
public let kVLCFilterParameterPropertyValueChangeActionKey = "ValueChangeAction"

// MARK: - VLCFilterParameter
@objc public final class VLCFilterParameter: NSObject {
      @objc public var value: AnyObject {
         get { return properties[kVLCFilterParameterPropertyPropertyValueKey] as! AnyObject }
         set {
             let newValue = (newValue as AnyObject).floatValue
             let currentValue = (properties[kVLCFilterParameterPropertyPropertyValueKey] as AnyObject).floatValue
             if newValue == currentValue { return }
             
             let maxValue = (properties[kVLCFilterParameterPropertyMaxValueKey] as AnyObject).floatValue
             let minValue = (properties[kVLCFilterParameterPropertyMinValueKey] as AnyObject).floatValue
             let clamped = max(min(newValue, maxValue), minValue)
             properties[kVLCFilterParameterPropertyPropertyValueKey] = NSNumber(value: clamped)
             
             if let action = properties[kVLCFilterParameterPropertyValueChangeActionKey] as? ((Any) -> Void) {
                 action(self.value)
                 }
             }
         }
    
      @objc public var defaultValue: AnyObject {
         return properties[kVLCFilterParameterPropertyDefaultValueKey] as AnyObject
         }
    
      @objc public var minValue: AnyObject {
         return properties[kVLCFilterParameterPropertyMinValueKey] as AnyObject
         }
    
      @objc public var maxValue: AnyObject {
         return properties[kVLCFilterParameterPropertyMaxValueKey] as AnyObject
         }
    
      @objc public func isValueSetToDefault() -> Bool {
         return (properties[kVLCFilterParameterPropertyPropertyValueKey] as AnyObject).floatValue ==
                 (properties[kVLCFilterParameterPropertyDefaultValueKey] as AnyObject).floatValue
         }
    
      @objc public static func create(withProperties properties: [String: AnyObject]) -> VLCFilterParameter {
         return VLCFilterParameter(properties: properties)
         }
    
      @objc public init(properties: [String: AnyObject]) {
         self.properties = properties.mutableCopy() as! NSMutableDictionary
         self.properties[kVLCFilterParameterPropertyPropertyValueKey] =
              (properties[kVLCFilterParameterPropertyDefaultValueKey] as AnyObject).copy()
         }
    
    private var properties: NSMutableDictionary
}

// MARK: - VLCFilter protocol
@objc public protocol VLCFilter: AnyObject {
    var mediaPlayer: VLCMediaPlayer { get }
    var enabled: Bool { get set }
    var parameters: [String: VLCFilterParameter] { get }
    func resetParametersIfNeeded() -> Bool
    func applyParameters(from otherFilter: VLCFilter)
}

// MARK: - VLCAdjustFilter constants
public let kVLCAdjustFilterContrastParameterKey = "Contrast"
public let kVLCAdjustFilterBrightnessParameterKey = "Brightness"
public let kVLCAdjustFilterHueParameterKey = "Hue"
public let kVLCAdjustFilterSaturationParameterKey = "Saturation"
public let kVLCAdjustFilterGammaParameterKey = "Gamma"

// MARK: - VLCAdjustFilter
@objc public final class VLCAdjustFilter: NSObject, VLCFilter {
    
      @objc public var mediaPlayer: VLCMediaPlayer { _mediaPlayer }
    private let _mediaPlayer: VLCMediaPlayer
    
      @objc public private(set) var contrast: VLCFilterParameter
      @objc public private(set) var brightness: VLCFilterParameter
      @objc public private(set) var hue: VLCFilterParameter
      @objc public private(set) var saturation: VLCFilterParameter
      @objc public private(set) var gamma: VLCFilterParameter
    
      @objc public var enabled: Bool {
         get { return _enabled }
         set {
             guard newValue != _enabled else { return }
             _enabled = newValue
             libvlc_video_set_adjust_int(_mediaPlayer.playerInstance, libvlc_adjust_Enable, newValue ? 1 : 0)
             }
         }
    private var _enabled: Bool = false
    
    public var parameters: [String: VLCFilterParameter] {
        get { return _parameters }
        }
    private var _parameters: [String: VLCFilterParameter]
    
      @objc public convenience init(mediaPlayer: VLCMediaPlayer) {
         self.init(mediaPlayer: mediaPlayer)
         }
    
      @objc public required init() {
          // Do nothing, use init(mediaPlayer:)
          self._mediaPlayer = VLCMediaPlayer()
          self.contrast = VLCFilterParameter(properties: [:])
          self.brightness = VLCFilterParameter(properties: [:])
          self.hue = VLCFilterParameter(properties: [:])
          self.saturation = VLCFilterParameter(properties: [:])
          self.gamma = VLCFilterParameter(properties: [:])
         }
    
      @objc public required init(mediaPlayer: VLCMediaPlayer) {
         self._mediaPlayer = mediaPlayer
         
         let contrastProps: [String: AnyObject] = [
             kVLCFilterParameterPropertyLibVLCFilterOptionKey: libvlc_adjust_Contrast as AnyObject,
             kVLCFilterParameterPropertyParameterKey: kVLCAdjustFilterContrastParameterKey as NSString,
             kVLCFilterParameterPropertyDefaultValueKey: 1.0 as AnyObject,
             kVLCFilterParameterPropertyMinValueKey: 0.0 as AnyObject,
             kVLCFilterParameterPropertyMaxValueKey: 2.0 as AnyObject,
             ]
         self.contrast = VLCFilterParameter(properties: contrastProps)
        
         let brightnessProps: [String: AnyObject] = [
             kVLCFilterParameterPropertyLibVLCFilterOptionKey: libvlc_adjust_Brightness as AnyObject,
             kVLCFilterParameterPropertyParameterKey: kVLCAdjustFilterBrightnessParameterKey as NSString,
             kVLCFilterParameterPropertyDefaultValueKey: 1.0 as AnyObject,
             kVLCFilterParameterPropertyMinValueKey: 0.0 as AnyObject,
             kVLCFilterParameterPropertyMaxValueKey: 2.0 as AnyObject,
             ]
         self.brightness = VLCFilterParameter(properties: brightnessProps)
        
         let hueProps: [String: AnyObject] = [
             kVLCFilterParameterPropertyLibVLCFilterOptionKey: libvlc_adjust_Hue as AnyObject,
             kVLCFilterParameterPropertyParameterKey: kVLCAdjustFilterHueParameterKey as NSString,
             kVLCFilterParameterPropertyDefaultValueKey: 0.0 as AnyObject,
             kVLCFilterParameterPropertyMinValueKey: -180.0 as AnyObject,
             kVLCFilterParameterPropertyMaxValueKey: 180.0 as AnyObject,
             ]
         self.hue = VLCFilterParameter(properties: hueProps)
        
         let saturationProps: [String: AnyObject] = [
             kVLCFilterParameterPropertyLibVLCFilterOptionKey: libvlc_adjust_Saturation as AnyObject,
             kVLCFilterParameterPropertyParameterKey: kVLCAdjustFilterSaturationParameterKey as NSString,
             kVLCFilterParameterPropertyDefaultValueKey: 1.0 as AnyObject,
             kVLCFilterParameterPropertyMinValueKey: 0.0 as AnyObject,
             kVLCFilterParameterPropertyMaxValueKey: 3.0 as AnyObject,
             ]
         self.saturation = VLCFilterParameter(properties: saturationProps)
        
         let gammaProps: [String: AnyObject] = [
             kVLCFilterParameterPropertyLibVLCFilterOptionKey: libvlc_adjust_Gamma as AnyObject,
             kVLCFilterParameterPropertyParameterKey: kVLCAdjustFilterGammaParameterKey as NSString,
             kVLCFilterParameterPropertyDefaultValueKey: 1.0 as AnyObject,
             kVLCFilterParameterPropertyMinValueKey: 0.01 as AnyObject,
             kVLCFilterParameterPropertyMaxValueKey: 10.0 as AnyObject,
             ]
         self.gamma = VLCFilterParameter(properties: gammaProps)
        
         super.init()
         _parameters = [contrast: contrast, brightness: brightness, hue: hue, saturation: saturation, gamma: gamma]
         }
    
    public func resetParametersIfNeeded() -> Bool {
        guard !areParametersSetToDefault() else { return false }
        
        let enabled = self.enabled
         [contrast, brightness, hue, saturation, gamma].forEach { param in
             param.value = param.defaultValue
             }
        self.enabled = enabled
        return true
        }
    
    public func applyParameters(from otherFilter: VLCFilter) {
        guard let other = otherFilter as? VLCAdjustFilter else { return }
        let enabled = self.enabled
         [
             (kVLCAdjustFilterContrastParameterKey, contrast, other.contrast),
             (kVLCAdjustFilterBrightnessParameterKey, brightness, other.brightness),
             (kVLCAdjustFilterHueParameterKey, hue, other.hue),
             (kVLCAdjustFilterSaturationParameterKey, saturation, other.saturation),
             (kVLCAdjustFilterGammaParameterKey, gamma, other.gamma),
         ].forEach { (key, current, otherParam) in
             current.value = otherParam.value
             }
        self.enabled = enabled
        }
    
    private func areParametersSetToDefault() -> Bool {
        return [contrast, brightness, hue, saturation, gamma].allSatisfy { $0.isValueSetToDefault() }
        }
}
