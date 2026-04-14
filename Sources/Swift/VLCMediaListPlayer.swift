//
//  VLCMediaListPlayer.swift
//  VLCKit
//
//  VLCMediaListPlayer - Media list player for VLC playback
//

import Foundation

/**
 Protocol for media list player delegate
 */
public protocol VLCMediaListPlayerDelegate: AnyObject {
    func mediaListPlayer(_ player: VLCMediaListPlayer, didPlayMedia media: VLCMedia)
    func mediaListPlayer(_ player: VLCMediaListPlayer, didPauseMedia media: VLCMedia)
    func mediaListPlayer(_ player: VLCMediaListPlayer, didStopMedia media: VLCMedia)
    func mediaListPlayerDidEndReached(_ player: VLCMediaListPlayer)
    func mediaListPlayer(_ player: VLCMediaListPlayer, didFailMedia media: VLCMedia)
    func mediaListPlayer(_ player: VLCMediaListPlayer, mediaError media: VLCMedia, withError error: Error?)
}

/**
 VLCMediaListPlayer - Media list player for sequential playback
 */
public class VLCMediaListPlayer: NSObject {

    public weak var delegate: (any VLCMediaListPlayerDelegate)?

    private var _mediaList: VLCMediaList?
    private var _player: VLCMediaPlayer?
    private var _currentIndex: Int = -1
    private var _isPlaying: Bool = false
    private var _playbackQueue: [VLCMedia] = []
    private let _playbackQueueLock = DispatchQueue(label: "org.videolan.mediaListPlayer.queue")

    /**
     Create a new media list player
     */
    public override init() {
        super.init()
        _mediaList = VLCMediaList()
        _player = VLCMediaPlayer()
        setupPlayerNotifications()
    }

    private func setupPlayerNotifications() {
        guard let player = _player else { return }
        player.delegate = self
    }

    private func playNextMedia() {
        _playbackQueueLock.sync { [weak self] in
            guard let self = self else { return }

            if self._currentIndex + 1 < self._playbackQueue.count {
                self._currentIndex += 1
                self.playMedia(atIndex: self._currentIndex)
            } else {
                self.delegate?.mediaListPlayerDidEndReached(self)
                self.stop()
            }
        }
    }

    private func playMedia(atIndex index: Int) {
        guard index >= 0 && index < _playbackQueue.count else { return }

        let media = _playbackQueue[index]
        _player?.setMedia(media)
        _player?.play()
        _isPlaying = true

        delegate?.mediaListPlayer(self, didPlayMedia: media)
    }

    public func play(atIndex index: Int) {
        _playbackQueueLock.sync { [weak self] in
            guard let self = self else { return }
            self._currentIndex = index
            self._playbackQueue = self._mediaList?.mediaObjects ?? []
            self.playMedia(atIndex: index)
        }
    }

    public func play() {
        guard let mediaList = _mediaList, mediaList.count > 0 else { return }

        _playbackQueueLock.sync { [weak self] in
            guard let self = self else { return }
            self._currentIndex = 0
            self._playbackQueue = self._mediaList?.mediaObjects ?? []
            self.playMedia(atIndex: 0)
        }
    }

    public func pause() {
        _player?.pause()
        _isPlaying = false

        guard let media = currentMedia else { return }
        delegate?.mediaListPlayer(self, didPauseMedia: media)
    }

    public func stop() {
        _player?.stop()
        _isPlaying = false
        _currentIndex = -1
    }

    public func playOrPause() {
        if _isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func previous() {
        _playbackQueueLock.sync { [weak self] in
            guard let self = self else { return }
            if self._currentIndex > 0 {
                self._currentIndex -= 1
                self.playMedia(atIndex: self._currentIndex)
            }
        }
    }

    public func next() {
        playNextMedia()
    }

    public var currentMedia: VLCMedia? {
        guard _currentIndex >= 0 && _currentIndex < _playbackQueue.count else { return nil }
        return _playbackQueue[_currentIndex]
    }

    public var numberOfMedia: Int {
        return _playbackQueue.count
    }

    public var isPlaying: Bool {
        return _isPlaying
    }

    public var mediaList: VLCMediaList? {
        get { return _mediaList }
        set {
            _mediaList = newValue
            _playbackQueueLock.sync { [weak self] in
                self?._playbackQueue = newValue?.mediaObjects ?? []
            }
        }
    }

    public func addMedia(_ media: VLCMedia) {
        _mediaList?.addMedia(media)
        _playbackQueueLock.sync { [weak self] in
            self?._playbackQueue.append(media)
        }
    }

    public func insertMedia(_ media: VLCMedia, atIndex index: Int) {
        _mediaList?.insertMedia(media, atIndex: index)
        _playbackQueueLock.sync { [weak self] in
            self?._playbackQueue.insert(media, at: index)
        }
    }

    public func removeMedia(atIndex index: Int) {
        _mediaList?.removeMedia(atIndex: index)
        _playbackQueueLock.sync { [weak self] in
            guard let self = self else { return }
            guard index >= 0 && index < self._playbackQueue.count else { return }
            self._playbackQueue.remove(at: index)
            if self._currentIndex == index {
                self._currentIndex = -1
            } else if self._currentIndex > index {
                self._currentIndex -= 1
            }
        }
    }

    deinit {
        stop()
        _player?.delegate = nil
    }
}

// MARK: - VLCMediaPlayerDelegate

extension VLCMediaListPlayer: VLCMediaPlayerDelegate {
    public func mediaPlayerTimeChanged(_ notification: Notification) {
    }

    public func mediaPlayerStateChanged(_ notification: Notification) {
        guard let player = _player else { return }

        switch player.state {
        case .ended:
            delegate?.mediaListPlayerDidEndReached(self)
            playNextMedia()
        case .error:
            guard let media = currentMedia else { break }
            delegate?.mediaListPlayer(self, mediaError: media, withError: nil)
            stop()
        default:
            break
        }
    }

    public func mediaPlayerTitleChanged(_ notification: Notification) {
    }

    public func mediaPlayerChapterChanged(_ notification: Notification) {
    }

    public func mediaPlayerLoudnessChanged(_ loudness: VLCMediaLoudness) {
    }

    public func mediaPlayerSnapshot(_ fileName: String) {
    }

    public func mediaPlayerStartedRecording(_ mediaPlayer: VLCMediaPlayer) {
    }

    public func mediaPlayer(_ mediaPlayer: VLCMediaPlayer, recordingStoppedAtPath path: String) {
    }
}
