import Foundation

public extension VLCMediaList {
     static var itemAddedNotification: NSNotificationName {
         NSNotificationName("VLCMediaListItemAddedNotification")
      }
      
     static var itemDeletedNotification: NSNotificationName {
         NSNotificationName("VLCMediaListItemDeletedNotification")
      }
      
     @objc func add(_ media: VLCMedia) -> UInt {
         addMedia(media)
      }
}
