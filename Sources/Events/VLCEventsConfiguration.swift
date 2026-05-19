import Foundation

/// Swift namespace for event configuration types
public enum VLCEventsConfigurationType {
    /// Default configuration - events dispatched synchronously on the caller's queue
    case `default`
    /// Legacy configuration - events dispatched asynchronously on the main queue
    case legacy
}

/// Protocol for configuring how events are dispatched
@objc public protocol VLCEventsConfiguring: AnyObject {
    func dispatchQueue() -> DispatchQueue?
    func isAsync() -> Bool
}

/// Default event configuration - synchronous, no specific queue
@objc public final class VLCEventsDefaultConfiguration: NSObject, VLCEventsConfiguring {
    public func dispatchQueue() -> DispatchQueue? { nil }
    public func isAsync() -> Bool { false }
}

/// Legacy event configuration - asynchronous on main queue
@objc public final class VLCEventsLegacyConfiguration: NSObject, VLCEventsConfiguring {
    public func dispatchQueue() -> DispatchQueue? { .main }
    public func isAsync() -> Bool { true }
}
