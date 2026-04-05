//
//  VLCMediaListPlayer.swift
//  VLCKit
//
//  VLCMediaListPlayer - Media list player for VLC playback
//

import Foundation

/**
 Notification name for media list player events
 */
public let VLCMediaListPlayerMediaPlayed = "VLCMediaListPlayerMediaPlayed"
public let VLCMediaListPlayerMediaPaused = "VLCMediaListPlayerMediaPaused"
public let VLCMediaListPlayerMediaStopped = "VLCMediaListPlayerMediaStopped"
public let VLCMediaListPlayerEndReached = "VLCMediaListPlayerEndReached"
public let VLCMediaListPlayerMediaFailed = "VLCMediaListPlayerMediaFailed"
public let VLCMediaListPlayerMediaError = "VLCMediaListPlayerMediaError"

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

    public weak var delegate: (any VLCMediaListPlayerDelegate)? = nil

    private var _mediaList: VLCMediaList?
    private var _player: VLCMediaPlayer?
    private var _currentIndex: Int = -1
    private var _isPlaying: Bool = false
    private var _playbackQueue: [VLCMedia] = []
    private var _playbackQueueLock: DispatchQueue?
    private var _eventsHandler: VLCEventsHandler?

    /**
     Create a new media list player
     */
    public override init() {
        super.init()
        _mediaList = VLCMediaList()
        _player = VLCMediaPlayer()
        _playbackQueueLock = DispatchQueue(label: "org.videolan.mediaListPlayer.queue", attributes: .concurrent)
        setupPlayerNotifications()
     }

    private func setupPlayerNotifications() {
        guard let player = _player else { return }

        player.delegate = self
        _eventsHandler = VLCEventsHandler(object: self, configuration: VLCLibrary.sharedEventsConfiguration)

        let eventsManager = libvlc_media_player_event_manager(player._playerInstance)
        guard let eventsManager = eventsManager else { return }

        let userData = Unmanaged.passRetained(_eventsHandler!).toOpaque()

        _playbackQueueLock?.async {
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerPlaying, HandleMediaListPlayerPlayed, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerPaused, HandleMediaListPlayerPaused, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerStopped, HandleMediaListPlayerStopped, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerEndReached, HandleMediaListPlayerEndReached, userData)
            libvlc_event_attach(eventsManager, libvlc_MediaPlayerEncounteredError, HandleMediaListPlayerError, userData)
           }
        }

    private func playNextMedia() {
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
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
        _player?.media = media
        _player?.play()
        _isPlaying = true

        delegate?.mediaListPlayer(self, didPlayMedia: media)
     }

    public func play(atIndex index: Int) {
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self._currentIndex = index
            self._playbackQueue = self._mediaList?._mediaObjects ?? []
            self.playMedia(atIndex: index)
           }
        }

    public func play() {
        guard let mediaList = _mediaList, mediaList.count > 0 else { return }

        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self._currentIndex = 0
            self._playbackQueue = self._mediaList?._mediaObjects ?? []
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

        guard let media = currentMedia else { return }
        delegate?.mediaListPlayer(self, didStopMedia: media)
     }

    public func playOrPause() {
        if _isPlaying {
            pause()
         } else {
            play()
         }
        }

    public func previous() {
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if self._currentIndex > 0 {
                self._currentIndex -= 1
                self.playMedia(atIndex: self._currentIndex)
             } else if self._currentIndex == 0 && self._playbackQueue.count > 1 {
                self._currentIndex = self._playbackQueue.count - 1
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
            _playbackQueueLock?.async(flags: .barrier) { [weak self] in
                self?._playbackQueue = newValue?._mediaObjects ?? []
             }
           }
        }

    public func addMedia(_ media: VLCMedia) {
        _mediaList?.addMedia(media)
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            self?._playbackQueue.append(media)
           }
        }

    public func insertMedia(_ media: VLCMedia, atIndex index: Int) {
        _mediaList?.insertMedia(media, atIndex: index)
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            self?._playbackQueue.insert(media, at: index)
           }
        }

    public func removeMedia(atIndex index: Int) {
        _mediaList?.removeMedia(atIndex: index)
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            guard index >= 0 && index < self._playbackQueue.count else { return }
            self._playbackQueue.remove(at: index)
            if self._currentIndex == index {
                self._currentIndex = -1
                self.stop()
             } else if self._currentIndex > index {
                self._currentIndex -= 1
             }
           }
        }

    public func playMediaList(_ mediaList: VLCMediaList) {
        self._mediaList = mediaList
        play()
     }

    public func setMediaList(_ mediaList: VLCMediaList) {
        self._mediaList = mediaList
        _playbackQueueLock?.async(flags: .barrier) { [weak self] in
            self?._playbackQueue = mediaList._mediaObjects
           }
        }

    deinit {
        stop()
        _player?.delegate = nil
        _mediaList?.delegate = nil
        _eventsHandler = nil
        _playbackQueueLock = nil
     }
}

// MARK: - VLCMediaPlayerDelegate

extension VLCMediaListPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ notification: Notification) {
        // Handle time changes if needed
     }

    func mediaPlayerStateChanged(_ notification: Notification) {
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

    func mediaPlayerTitleChanged(_ notification: Notification) {
        // Handle title changes if needed
     }

    func mediaPlayerChapterChanged(_ notification: Notification) {
        // Handle chapter changes if needed
     }

    func mediaPlayerLoudnessChanged(_ loudness: VLCMediaLoudness) {
        // Handle loudness changes if needed
     }

    func mediaPlayerSnapshot(_ fileName: String) {
        // Handle snapshot events if needed
     }

    func mediaPlayerStartedRecording(_ mediaPlayer: VLCMediaPlayer) {
        // Handle recording start if needed
     }

    func mediaPlayer(_ mediaPlayer: VLCMediaPlayer, recordingStoppedAtPath path: String) {
        // Handle recording stop if needed
     }
}

// MARK: - Event Handlers

private func HandleMediaListPlayerPlayed(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let eventsHandler = opaque.map({ Unmanaged<VLCMediaListPlayer>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let player = object as! VLCMediaListPlayer
        // Handled via delegate in player
       }
}

private func HandleMediaListPlayerPaused(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let eventsHandler = opaque.map({ Unmanaged<VLCMediaListPlayer>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let player = object as! VLCMediaListPlayer
        // Handled via delegate in player
       }
}

private func HandleMediaListPlayerStopped(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let eventsHandler = opaque.map({ Unmanaged<VLCMediaListPlayer>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let player = object as! VLCMediaListPlayer
        // Handled via delegate in player
       }
}

private func HandleMediaListPlayerEndReached(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let eventsHandler = opaque.map({ Unmanaged<VLCMediaListPlayer>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let player = object as! VLCMediaListPlayer
        player.delegate?.mediaListPlayerDidEndReached(player)
       }
}

private func HandleMediaListPlayerError(_ event: libvlc_event_t, opaque: UnsafeMutableRawPointer?) {
    guard let eventsHandler = opaque.map({ Unmanaged<VLCMediaListPlayer>.from($0).takeUnretainedValue() }) else { return }

    eventsHandler.handleEvent { object in
        let player = object as! VLCMediaListPlayer
        player.delegate?.mediaListPlayer(player, mediaError: player.currentMedia ?? VLCMedia(), withError: nil)
       }
}
