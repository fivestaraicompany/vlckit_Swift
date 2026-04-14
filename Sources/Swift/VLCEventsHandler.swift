//
//  VLCEventsHandler.swift
//  VLCKit
//
//  VLCEventsHandler - Events handler
//

import Foundation

/**
 VLCEventsHandler - Events handler for libvlc callbacks
 */
public final class VLCEventsHandler: NSObject {

    private weak var _object: NSObject?
    private var _configuration: (any VLCEventsConfiguring)?

    /**
     Create a new events handler

     - Parameter object: The object to handle events for
     - Parameter configuration: The event configuration
     */
    public init(object: NSObject, configuration: (any VLCEventsConfiguring)?) {
        _object = object
        _configuration = configuration
        super.init()
    }

    public func handleEvent(_ handler: @escaping (NSObject) -> Void) {
        guard let object = _object else { return }

        let block: () -> Void = {
            handler(object)
        }

        if let dispatchQueue = _configuration?.dispatchQueue {
            if _configuration?.isAsync == true {
                dispatchQueue.async(execute: block)
            } else {
                dispatchQueue.sync(execute: block)
            }
        } else {
            block()
        }
    }
}
