import Foundation

public extension VLCEvents {
    struct DefaultConfiguration: VLCEventsConfiguring {
        public func dispatchQueue() -> DispatchQueue? {
            return nil
          }
        
        public func isAsync() -> Bool {
            return false
          }
      }
    
    struct LegacyConfiguration: VLCEventsConfiguring {
        public func dispatchQueue() -> DispatchQueue? {
            return DispatchQueue.main
          }
        
        public func isAsync() -> Bool {
            return true
          }
      }
}
