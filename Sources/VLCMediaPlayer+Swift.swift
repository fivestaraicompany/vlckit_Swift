//
//  VLCMediaPlayer+Swift.swift
//  MobileVLCKit
//
//  Swift extensions for VLCMediaPlayer
//

import Foundation
import MobileVLCKit

extension VLCMediaPlayer {
    
    /// 재생 상태
    var playStateString: String {
        switch playState {
        case VLCPlaying:
            return "Playing"
        case VLCPaused:
            return "Paused"
        case VLCStopped:
            return "Stopped"
        case VLCOpening:
            return "Opening"
        case VLCError:
            return "Error"
        default:
            return "Unknown"
        }
    }
    
    /// 현재 재생 시간
    var currentTime: TimeInterval {
        get {
            return timePlayed
        }
        set {
            seek(newValue)
        }
    }
    
    /// 전체 길이
    var duration: TimeInterval {
        return totalLength
    }
    
    /// 재생 비율 (0.0 - 1.0)
    var playbackRate: Double {
        get {
            return rate
        }
        set {
            setRate(Float(newValue))
        }
    }
    
    /// 볼륨 (0 - 200)
    var volume: Int {
        get {
            return volume
        }
        set {
            setVolume(newValue)
        }
    }
    
    /// 무음 토글
    func toggleMute() {
        isMute ? setMute(false) : setMute(true)
    }
    
    /// 현재 미uting 상태
    var isMuted: Bool {
        return isMute
    }
    
    /// 오디오 트랙 목록
    var availableAudioTracks: [VLCAudioTrack] {
        return audioTracks ?? []
    }
    
    /// 비디오 트랙 목록
    var availableVideoTracks: [VLCVideoTrack] {
        return videoTracks ?? []
    }
    
    /// 자막 목록
    var availableSubtitles: [VLCSubTitle] {
        return subtitles ?? []
    }
}

extension VLCMedia {
    
    /// 메타데이터
    var metadata: [String: Any] {
        return [
            "title": title,
            "url": url?.absoluteString ?? "",
            "length": length,
            "mime": mime
        ]
    }
    
    /// 파일 크기
    var fileSize: Int64 {
        return size
    }
    
    /// MIME 타입
    var mimeType: String {
        return mime
    }
    
    /// 재생 가능 여부
    var isPlayable: Bool {
        return state == VLCStateReady || state == VLCStateOpened
    }
}

extension VLCMediaList {
    
    /// 미디어 개수
    var count: Int {
        return count
    }
    
    /// 특정 인덱스의 미디어
    func media(at index: Int) -> VLCMedia? {
        return objectAtIndex(index)
    }
    
    /// 모든 미디어 URL 목록
    var allURLs: [URL] {
        var urls: [URL] = []
        for i in 0..<count {
            if let media = objectAtIndex(i), let url = media.url {
                urls.append(url)
            }
        }
        return urls
    }
    
    /// 미디어 추가
    func addMedia(_ media: VLCMedia) {
        addMedia(media)
    }
    
    /// URL 로 미디어 추가
    func addMedia(withURL url: URL) {
        let media = VLCMedia(url: url)
        addMedia(media)
    }
    
    /// 인덱스 제거
    func removeMedia(at index: Int) {
        removeMedia(at: index)
    }
}
