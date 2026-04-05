//
//  VLCMediaThumbnailer.swift
//  VLCKit
//
//  VLCMediaThumbnailer - Media thumbnailer
//

import Foundation
import CoreGraphics

/**
 Protocol for media thumbnailer delegate
 */
public protocol VLCMediaThumbnailerDelegate: AnyObject {
    func mediaThumbnailer(_ thumbnailer: VLCMediaThumbnailer, didFinishThumbnail image: CGImage?)
    func mediaThumbnailerDidTimeOut(_ thumbnailer: VLCMediaThumbnailer)
}

/**
 VLCMediaThumbnailer - Media thumbnailer for VLC
 */
public class VLCMediaThumbnailer: NSObject {

    public weak var delegate: (any VLCMediaThumbnailerDelegate)? = nil
    public private(set) var media: VLCMedia? = nil
    public private(set) var thumbnail: CGImage? = nil
    public private(set) var thumbnailWidth: CGFloat = 0
    public private(set) var thumbnailHeight: CGFloat = 0
    public private(set) var snapshotPosition: Float = 0.3
    public private(set) var shouldRejectFrames: Bool = false
    public private(set) var dataPointer: UnsafeMutableRawPointer? = nil

    private var _library: VLCLibrary?
    private var _playerInstance: OpaquePointer? = nil
    private var _parsingTimeoutSource: DispatchSourceTimer? = nil
    private var _thumbnailingTimeoutSource: DispatchSourceTimer? = nil
    private var _numberOfReceivedFrames: Int = 0
    private var _effectiveThumbnailHeight: CGFloat = 0
    private var _effectiveThumbnailWidth: CGFloat = 0

    private let kDefaultImageWidth: CGFloat = 320
    private let kDefaultImageHeight: CGFloat = 240
    private let kSnapshotPosition: Float = 0.3
    private let kStandardStartTime: Int64 = 150000

    public static func thumbnailer(withMedia media: VLCMedia, delegate: (any VLCMediaThumbnailerDelegate)?) -> VLCMediaThumbnailer {
        let thumbnailer = VLCMediaThumbnailer()
        thumbnailer.media = media
        thumbnailer.delegate = delegate
        thumbnailer._library = VLCLibrary.sharedLibrary
        return thumbnailer
     }

    public static func thumbnailer(withMedia media: VLCMedia, delegate: (any VLCMediaThumbnailerDelegate)?, library: VLCLibrary?) -> VLCMediaThumbnailer {
        let thumbnailer = VLCMediaThumbnailer()
        thumbnailer.media = media
        thumbnailer.delegate = delegate
        thumbnailer._library = library ?? VLCLibrary.sharedLibrary
        return thumbnailer
     }

    deinit {
        NSAssert(_thumbnailingTimeoutSource == nil, "Timer not released")
        NSAssert(_parsingTimeoutSource == nil, "Timer not released")
        NSAssert(dataPointer == nil, "Data not released")
        NSAssert(_playerInstance == nil, "Not properly retained")

        thumbnail = nil
     }

    public var library: VLCLibrary? {
        get { return _library }
        set { _library = newValue }
     }

    public func fetchThumbnail() {
        NSAssert(dataPointer == nil, "We are already fetching a thumbnail")

        let parsedStatus = media?.parseStatus ?? .notParsed
        if parsedStatus != .failed && parsedStatus != .done {
            media?.addObserver(self, forKeyPath: "parseStatus", options: [], context: nil)
            media?.parse(options: [.local, .network])
            _parsingTimeoutSource = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        _parsingTimeoutSource?.schedule(deadline: .now() + 10)
        _parsingTimeoutSource?.setEventHandler { [weak self] in
            self?.mediaParsingTimedOut()
          }
        _parsingTimeoutSource?.resume()
            return
         }

        startFetchingThumbnail()
     }

    private func startFetchingThumbnail() {
        guard let media = media else { return }

        let tracks = media.tracksInformation

        var videoTrack: [String: Any]? = nil
        for track in tracks {
            if let type = track[VLCMediaTracksInformationType] as? String, type == VLCMediaTracksInformationTypeVideo {
                videoTrack = track
                break
             }
         }

        var imageWidth: CGFloat = thumbnailWidth > 0 ? thumbnailWidth : kDefaultImageWidth
        var imageHeight: CGFloat = thumbnailHeight > 0 ? thumbnailHeight : kDefaultImageHeight
        var snapshotPosition = self.snapshotPosition > 0 ? self.snapshotPosition : kSnapshotPosition

        if let videoTrack = videoTrack {
            if let videoHeight = videoTrack[VLCMediaTracksInformationVideoHeight] as? Int,
               let videoWidth = videoTrack[VLCMediaTracksInformationVideoWidth] as? Int {

                var ratio: Double
                if Double(imageWidth) / Double(imageHeight) < Double(videoWidth) / Double(videoHeight) {
                    ratio = Double(imageHeight) / Double(videoHeight)
                 } else {
                    ratio = Double(imageWidth) / Double(videoWidth)
                 }

                let newWidth = Int(round(Double(videoWidth) * ratio))
                let newHeight = Int(round(Double(videoHeight) * ratio))

                imageWidth = CGFloat(newWidth > 0 ? newWidth : Int(imageWidth))
                imageHeight = CGFloat(newHeight > 0 ? newHeight : Int(imageHeight))
             }
         }

        _numberOfReceivedFrames = 0
        NSAssert(!shouldRejectFrames, "Are we still running?")

        _effectiveThumbnailHeight = imageHeight
        _effectiveThumbnailWidth = imageWidth
        self.snapshotPosition = snapshotPosition

        dataPointer = calloc(1, Int(imageWidth * imageHeight * 4))
        NSAssert(dataPointer != nil, "Can't create data")

        NSAssert(_playerInstance == nil, "We are already fetching a thumbnail")
        _playerInstance = libvlc_media_player_new(_library?.instance)
        if _playerInstance == nil {
            NSAssert(false, "Creating the player instance failed")
            endThumbnailing()
            return
         }

        libvlc_media_add_option(media.libVLCMediaDescriptor, "no-audio")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "no-spu")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "avcodec-threads=1")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "avcodec-skip-idct=4")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "avcodec-skiploopfilter=3")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "deinterlace=-1")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "avi-index=3")
        libvlc_media_add_option(media.libVLCMediaDescriptor, "codec=avcodec,none")

        libvlc_media_player_set_media(_playerInstance, media.libVLCMediaDescriptor)
        libvlc_video_set_format(_playerInstance, "RGBA", Int(imageWidth), Int(imageHeight), 4 * Int(imageWidth))
        libvlc_video_set_callbacks(_playerInstance, lockFunction, unlockFunction, displayFunction, Unmanaged.passRetained(self).toOpaque())

        if snapshotPosition == kSnapshotPosition {
            let length = media.length?.intValue ?? 0
            if length < kStandardStartTime {
                if length > 1000 {
                    let startValue = (length * 25 / 100000)
                    libvlc_media_add_option(media.libVLCMediaDescriptor, "start-time=\(startValue)")
                 }
             } else {
                libvlc_media_add_option(media.libVLCMediaDescriptor, "start-time=\(kStandardStartTime / 1000)")
             }
         }

        libvlc_media_player_play(_playerInstance)

        guard let url = media.url else { return }
        var timeoutDuration: TimeInterval = 10
        if url.scheme != "file" {
            timeoutDuration = 45
         }

        _thumbnailingTimeoutSource = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
         _thumbnailingTimeoutSource?.schedule(deadline: .now() + timeoutDuration)
         _thumbnailingTimeoutSource?.setEventHandler { [weak self] in
            self?.mediaThumbnailingTimedOut()
           }
         _thumbnailingTimeoutSource?.resume()
     }

    private func mediaParsingTimedOut() {
        print("WARNING: media thumbnailer media parsing timed out")

        media?.removeObserver(self, forKeyPath: "parseStatus")

        startFetchingThumbnail()
     }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if object == media, keyPath == "parseStatus" {
            _parsingTimeoutSource?.cancel()
             _parsingTimeoutSource = nil
            media?.removeObserver(self, forKeyPath: "parseStatus")
            startFetchingThumbnail()
            return
         }
         super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
     }

    private func didFetchThumbnail() {
        guard !shouldRejectFrames else { return }

        _numberOfReceivedFrames += 1

        let position = libvlc_media_player_get_position(_playerInstance)
        let length = libvlc_media_player_get_length(_playerInstance)

        if position < self.snapshotPosition && _numberOfReceivedFrames < 1 {
            libvlc_media_player_set_position(_playerInstance, self.snapshotPosition)
            return
          }

        if _numberOfReceivedFrames < 1 {
            return
           }

        NSAssert(dataPointer != nil, "We have no data")

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = _effectiveThumbnailWidth
        let height = _effectiveThumbnailHeight
        let pitch = 4 * width

        let bitmap = CGContext(data: dataPointer,
                               bytesPerRow: Int(pitch),
                               size: CGSize(width: width, height: height),
                               bitsPerComponent: 8,
                               bitsPerPixel: Int(pitch * 8),
                               colorSpace: colorSpace,
                               bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

        CGColorSpaceRelease(colorSpace)
        NSAssert(bitmap != nil, "Can't create bitmap")

        thumbnail = bitmap?.makeImage()
        _thumbnailWidth = _effectiveThumbnailWidth
        _thumbnailHeight = _effectiveThumbnailHeight

        bitmap?.release()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notifyDelegate()
         }
     }

    private func stopAsync() {
        if let playerInstance = _playerInstance {
            libvlc_media_player_stop(playerInstance)
            libvlc_media_player_release(playerInstance)
             _playerInstance = nil
         }

        if let dataPointer = dataPointer {
            free(dataPointer)
             self.dataPointer = nil
         }

        shouldRejectFrames = false
     }

    private func endThumbnailing() {
        shouldRejectFrames = true

        _thumbnailingTimeoutSource?.cancel()
          _thumbnailingTimeoutSource = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.stopAsync()
           }
     }

    private func notifyDelegate() {
        endThumbnailing()

        delegate?.mediaThumbnailer(self, didFinishThumbnail: thumbnail)
     }

    private func mediaThumbnailingTimedOut() {
        print("WARNING: media thumbnailer media thumbnailing timed out")

        endThumbnailing()

        delegate?.mediaThumbnailerDidTimeOut(self)
     }

    private func lockFunction(opaque: UnsafeMutableRawPointer?, pixels: UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> UnsafeMutableRawPointer? {
        let thumbnailer = opaque!.load(as: VLCMediaThumbnailer.self)
        pixels?.pointee = thumbnailer.dataPointer
        assert(pixels?.pointee != nil)
        return nil
     }

    private func unlockFunction(opaque: UnsafeMutableRawPointer?, picture: UnsafeMutableRawPointer?, pixels: UnsafePointer<UnsafeMutableRawPointer?>?) {
    }

    private func displayFunction(opaque: UnsafeMutableRawPointer?, picture: UnsafeMutableRawPointer?) {
        let thumbnailer = opaque!.load(as: VLCMediaThumbnailer.self)
        assert(picture == nil)

        if thumbnailer.thumbnail != nil || thumbnailer.shouldRejectFrames {
            return
         }

        thumbnailer.didFetchThumbnail()
     }
}
