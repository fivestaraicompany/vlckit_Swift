import Foundation
import CoreGraphics

public extension VLCMediaThumbnailer {
       @objc var thumbnail: CGImage? { _thumbnail }
       @objc var media: VLCMedia { _media }
       @objc var thumbnailHeight: CGFloat { _thumbnailHeight }
       @objc var thumbnailWidth: CGFloat { _thumbnailWidth }
       @objc var snapshotPosition: Float { _snapshotPosition }
       @objc var delegate: VLCMediaThumbnailerDelegate? {
          get { _thumbnailingDelegate }
          set { _thumbnailingDelegate = newValue }
           }
      
    private var _thumbnail: CGImage?
    private var _media: VLCMedia
    private var _thumbnailingDelegate: VLCMediaThumbnailerDelegate?
    private var _thumbnailHeight: CGFloat = 240
    private var _thumbnailWidth: CGFloat = 320
    private var _snapshotPosition: Float = 0.3
    private var mp: libvlc_media_player_t?
    
       @objc static func thumbnailer(with media: VLCMedia, delegate: VLCMediaThumbnailerDelegate) -> VLCMediaThumbnailer {
           let thumbnailer = VLCMediaThumbnailer()
           thumbnailer.media = media
           thumbnailer.delegate = delegate
           thumbnailer.library = VLCLibrary.shared
           return thumbnailer
           }
      
       @objc static func thumbnailer(with media: VLCMedia, delegate: VLCMediaThumbnailerDelegate, library: VLCLibrary?) -> VLCMediaThumbnailer {
           let thumbnailer = VLCMediaThumbnailer()
           thumbnailer.media = media
           thumbnailer.delegate = delegate
           thumbnailer.library = library ?? VLCLibrary.shared
           return thumbnailer
           }
      
       @objc func fetchThumbnail() {
           guard mp == nil else { return }
          
           let parsedStatus = media.parsedStatus
           if parsedStatus != .done && parsedStatus != .failed {
               media.addObserver(self, forKeyPath: "parsedStatus", options: [], context: nil)
               media.parse()
               }
          
              // Start fetching after a delay to allow parsing
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
               self?.startFetchingThumbnail()
               }
           }
      
    private func startFetchingThumbnail() {
        guard mp == nil else { return }
        
        let length = media.length.intValue
        if length < 150000 {
            if length > 1000 {
                let seekTo = length * 25 / 100000
                let opt = "start-time=\(seekTo)"
                libvlc_media_add_option(media.libVLCMediaDescriptor, (opt as NSString).utf8String)
                }
             } else {
            let opt = "start-time=150000"
            libvlc_media_add_option(media.libVLCMediaDescriptor, (opt as NSString).utf8String)
             }
        
        mp = libvlc_media_player_new_from_media(media.libVLCMediaDescriptor)
        guard let player = mp else { return }
        
        libvlc_media_player_play(player)
        
        let timeoutDuration: TimeInterval = (media.url?.scheme != "file") ? 45 : 10
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutDuration) { [weak self] in
            self?.handleThumbnailingTimedOut()
             }
        }
    
    private func didFetchThumbnail() {
        guard mp != nil else { return }
        
        let position = libvlc_media_player_get_position(mp!)
        let length = libvlc_media_player_get_length(mp!)
        
        if position < snapshotPosition {
            libvlc_media_player_set_position(mp!, snapshotPosition, 1)
            return
             }
        
        let width = thumbnailWidth
        let height = thumbnailHeight
        let pitch = UInt32(4 * width)
        
        guard let data = malloc(Int(pitch * height)) else { return }
        defer { free(data) }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmap = CGBitmapContextCreate(data, Int(width), Int(height), 8, pitch, colorSpace, kCGImageAlphaNoneSkipLast)
        defer { CGColorSpaceRelease(colorSpace) }
        defer { CGContextRelease(bitmap) }
        
        guard let cgBitmap = bitmap else { return }
         _thumbnail = CGBitmapContextCreateImage(cgBitmap)
        
        DispatchQueue.main.async { [weak self] in
             self?.delegate?.mediaThumbnailer(self!, didFinishThumbnail: self?._thumbnail!)
            }
        }
    
    private func endThumbnailing() {
        if let player = mp {
            libvlc_media_player_stop_async(player)
            libvlc_media_player_release(player)
            }
        mp = nil
        }
    
    private func handleThumbnailingTimedOut() {
        endThumbnailing()
        delegate?.mediaThumbnailerDidTimeOut(self)
         }
      
        @objc var library: VLCLibrary {
           get { _library }
           set { _library = newValue }
           }
       private var _library: VLCLibrary
}

// MARK: - KVO observer
extension VLCMediaThumbnailer {
       @objc public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
           if keyPath == "parsedStatus" {
               startFetchingThumbnail()
               }
           }
}
