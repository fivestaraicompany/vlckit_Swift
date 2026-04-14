//
//  VLCEventsConfiguration.swift
//  VLCKit
//
//  VLCEventsConfiguration - Events configuration
//

import Foundation

/**
 VLCEventsDefaultConfiguration - Default event configuration
 */
public final class VLCEventsDefaultConfiguration: NSObject, VLCEventsConfiguring {

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
public final class VLCEventsLegacyConfiguration: NSObject, VLCEventsConfiguring {

    public var dispatchQueue: DispatchQueue? {
        return DispatchQueue.main
    }

    public var isAsync: Bool {
        return true
    }
}
