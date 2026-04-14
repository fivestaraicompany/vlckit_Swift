//
//  VLCMediaThumbnailer.swift
//  VLCKit
//
//  VLCMediaThumbnailer - Media thumbnailer
//

import Foundation
import CoreGraphics
import CLibVLC

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

    public weak var delegate: (any VLCMediaThumbnailerDelegate)?
    public var media: VLCMedia?
    public private(set) var thumbnail: CGImage?
    public var thumbnailWidth: CGFloat = 0
    public var thumbnailHeight: CGFloat = 0
    public var snapshotPosition: Float = 0.3

    private var _library: VLCLibrary?
    private var _playerInstance: OpaquePointer?
    private var _parsingTimeoutSource: DispatchSourceTimer?
    private var _thumbnailingTimeoutSource: DispatchSourceTimer?
    private var _numberOfReceivedFrames: Int = 0
    private var _effectiveThumbnailHeight: CGFloat = 0
    private var _effectiveThumbnailWidth: CGFloat = 0
    private var _dataPointer: UnsafeMutableRawPointer?
    private var _shouldRejectFrames: Bool = false

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
        if let data = _dataPointer {
            free(data)
        }
        if let player = _playerInstance {
            libvlc_media_player_release(player)
        }
    }

    public var library: VLCLibrary? {
        get { return _library }
        set { _library = newValue }
    }

    public func fetchThumbnail() {
        guard _dataPointer == nil else { return }

        let parsedStatus = media?.parseStatus ?? .initial
        if parsedStatus != .failed && parsedStatus != .done {
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

        var imageWidth: CGFloat = thumbnailWidth > 0 ? thumbnailWidth : kDefaultImageWidth
        var imageHeight: CGFloat = thumbnailHeight > 0 ? thumbnailHeight : kDefaultImageHeight

        _numberOfReceivedFrames = 0
        _shouldRejectFrames = false

        _effectiveThumbnailHeight = imageHeight
        _effectiveThumbnailWidth = imageWidth

        _dataPointer = calloc(1, Int(imageWidth * imageHeight * 4))
        guard _dataPointer != nil else { return }

        _playerInstance = libvlc_media_player_new(_library?.instance)
        guard _playerInstance != nil else {
            endThumbnailing()
            return
        }

        if let descriptor = media.libVLCMediaDescriptor {
            libvlc_media_add_option(descriptor, "no-audio")
            libvlc_media_add_option(descriptor, "no-spu")
            libvlc_media_add_option(descriptor, "avcodec-threads=1")
            libvlc_media_add_option(descriptor, "avcodec-skip-idct=4")
            libvlc_media_add_option(descriptor, "avcodec-skiploopfilter=3")
            libvlc_media_add_option(descriptor, "deinterlace=-1")
            libvlc_media_add_option(descriptor, "avi-index=3")
            libvlc_media_add_option(descriptor, "codec=avcodec,none")

            libvlc_media_player_set_media(_playerInstance, descriptor)
        }

        libvlc_video_set_format(_playerInstance, "RGBA", UInt32(imageWidth), UInt32(imageHeight), UInt32(4 * Int(imageWidth)))

        libvlc_media_player_play(_playerInstance)

        var timeoutDuration: TimeInterval = 10
        if let url = media.url, url.scheme != "file" {
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
        _parsingTimeoutSource?.cancel()
        _parsingTimeoutSource = nil
        startFetchingThumbnail()
    }

    private func endThumbnailing() {
        _shouldRejectFrames = true

        _thumbnailingTimeoutSource?.cancel()
        _thumbnailingTimeoutSource = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.stopAsync()
        }
    }

    private func stopAsync() {
        if let playerInstance = _playerInstance {
            libvlc_media_player_stop(playerInstance)
            libvlc_media_player_release(playerInstance)
            _playerInstance = nil
        }

        if let data = _dataPointer {
            free(data)
            _dataPointer = nil
        }

        _shouldRejectFrames = false
    }

    private func notifyDelegate() {
        endThumbnailing()
        delegate?.mediaThumbnailer(self, didFinishThumbnail: thumbnail)
    }

    private func mediaThumbnailingTimedOut() {
        endThumbnailing()
        delegate?.mediaThumbnailerDidTimeOut(self)
    }

    func didFetchThumbnail() {
        guard !_shouldRejectFrames else { return }

        _numberOfReceivedFrames += 1

        if _numberOfReceivedFrames < 2 {
            return
        }

        guard let data = _dataPointer else { return }

        let width = Int(_effectiveThumbnailWidth)
        let height = Int(_effectiveThumbnailHeight)
        let bytesPerRow = 4 * width

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let context = CGContext(data: data,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
            thumbnail = context.makeImage()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notifyDelegate()
        }
    }
}
