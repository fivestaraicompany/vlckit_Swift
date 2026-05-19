import Foundation

public extension VLCMediaList {
    static var itemAddedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaListItemAddedNotification")
        }
    
    static var itemDeletedNotification: NSNotificationName {
        return NSNotificationName("VLCMediaListItemDeletedNotification")
        }
    
    func add(_ media: VLCMedia) -> UInt {
        return addMedia(media)
        }
}
