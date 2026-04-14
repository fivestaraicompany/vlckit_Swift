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

    private var _object: NSObject?
    private var _configuration: (any VLCEventsConfiguring)?
    private var _releaseQueue: DispatchQueue?

        /**
     Create a new events handler

         - Parameter object: The object to handle events for
         - Parameter configuration: The event configuration
         - Returns: A new events handler instance
         */
    public convenience init?(object: NSObject?, configuration: (any VLCEventsConfiguring)?) {
        self.init()

         _object = object
         _configuration = configuration

        let attr = DispatchQueueAttribute(serial: true, qos: .userInitiated)
         _releaseQueue = DispatchQueue(label: "handler.releaseQueue", attributes: attr)

         object?.retain()
         }

    deinit {
         _object?.release()
         _object = nil
         _configuration = nil
         _releaseQueue = nil
         }

    public func handleEvent(_ handler: @escaping (NSObject) -> Void) {
        guard let object = _object else { return }

        let releaseQueue = _releaseQueue
        let block: () -> Void = {
            handler(object)
            releaseQueue?.sync {
                autoreleasepool {
                    object.release()
                }
             }
           }

        if let dispatchQueue = _configuration?.dispatchQueue {
            if _configuration?.isAsync == true {
                dispatchQueue.async(block)
                 } else {
                dispatchQueue.sync(block)
              }
             } else {
            block()
           }
         }
}

// MARK: - Extension

extension NSObject {
    func retain() {
        #if !canImport(ObjectModel)
        self.retain()
        #endif
         }

    func release() {
        #if !canImport(ObjectModel)
        self.release()
        #endif
         }
}
