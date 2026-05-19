import Foundation

@objc public final class VLCEventsHandler: NSObject {
    
    @objc public private(set) weak var object: AnyObject?
    private let releaseQueue: DispatchQueue
    private let configuration: VLCEventsConfiguring?
    private let _object: AnyObject
    
    @objc public static func handler(with object: AnyObject, configuration: VLCEventsConfiguring?) -> VLCEventsHandler {
        VLCEventsHandler(object: object, configuration: configuration)
     }
    
    @objc public func handleEvent(_ handle: @escaping (AnyObject) -> Void) {
        var object = _object
        guard let obj = object else { return }
        
        let releaseQueue = self.releaseQueue
        let block: () -> Void = {
            handle(obj)
            DispatchQueue.global(qos: .userInitiated).async {
                 @autoreleasepool {
                    object = nil
                 }
             }
         }
        
        if let queue = configuration?.dispatchQueue() {
            if configuration?.isAsync() ?? false {
                DispatchQueue.async(queue: queue, block: block)
             } else {
                DispatchQueue.sync(queue: queue, execute: block)
             }
         } else {
            block()
         }
     }
    
    @objc public required init(object: AnyObject, configuration: VLCEventsConfiguring?) {
        self._object = object
        self.object = object
        self.configuration = configuration
        self.releaseQueue = DispatchQueue(label: "handler.releaseQueue", attributes: .serial)
     }
}
