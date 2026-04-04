//
//  VLCEventsConfiguration.swift
//  VLCKit
//
//  VLCEventsConfiguration - Events configuration
//

import Foundation

/**
 Protocol for configuring events
 */
public protocol VLCEventsConfiguring {
    var dispatchQueue: DispatchQueue? { get }
    var isAsync: Bool { get }
}

/**
 VLCEventsDefaultConfiguration - Default event configuration
 */
public class VLCEventsDefaultConfiguration: NSObject, VLCEventsConfiguring {

    public var dispatchQueue: DispatchQueue? {
        return nil
        }

    public var isAsync: Bool {
        return false
        }
}

/**
 VLCEventsLegacyConfiguration - Legacy event configuration
 */
public class VLCEventsLegacyConfiguration: NSObject, VLCEventsConfiguring {

    public var dispatchQueue: DispatchQueue? {
        return DispatchQueue.main
        }

    public var isAsync: Bool {
        return true
        }
}
