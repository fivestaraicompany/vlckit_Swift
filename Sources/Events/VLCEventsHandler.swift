import Foundation

@objc public final class VLCEventsHandler: NSObject {
    
     @objc public private(set) weak var object: AnyObject?
    private let releaseQueue: DispatchQueue
    
     @objc public static func handler(with object: AnyObject, configuration: VLCEventsConfiguring?) -> VLCEventsHandler {
        return VLCEventsHandler(object: object, configuration: configuration)
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
                DispatchQueue.async(queue, block)
              } else {
                DispatchQueue.sync(queue, block)
              }
          } else {
            block()
          }
      }
    
     @objc public required init(object: AnyObject, configuration: VLCEventsConfiguring?) {
        self.object = object
        self.configuration = configuration
        self.releaseQueue = DispatchQueue(label: "handler.releaseQueue", attributes: .serial)
      }
    
    private weak var _object: AnyObject? {
        return object
      }
    
    private let configuration: VLCEventsConfiguring?
}
