# VLCKit Swift - SPM 지원 및 Swift Wrapper

🌸 **FiveStar AI Company** 의 VLC Mobile Kit 입니다.

## ✨ 주요 기능

- ✅ **SPM (Swift Package Manager) 지원**
- ✅ **Swift Wrapper 추가** - C API 를 Swift 에서 쉽게 사용
- ✅ **iOS, macOS, tvOS 플랫폼 지원**

## 📦 설치 방법

### SPM 으로 설치

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/fivestaraicompany/vlckit_Swift",
        from: "8.0.1"
    )
]
```

### Xcode 에서 설치

1. `File > Add Package Dependency`
2. 저장소 URL 입력: `https://github.com/fivestaraicompany/vlckit_Swift`
3. Tag `8.0.1` 선택
4. `MobileVLCKit` 제품 선택

## 🚀 사용 예시

### 기본 사용법

```swift
import MobileVLCKit

// MediaPlayer 생성
let player = VLCMediaPlayer()
let wrapper = VLCMediaPlayerWrapper(playerWithPlayer: player)

// 미디어 재생
if let url = URL(string: "https://example.com/video.mp4") {
    let media = VLCMedia(url: url)
    player.media = media
    wrapper.play()
}

// 재생 제어
wrapper.pause()
wrapper.seekToTime(30.0) // 30 초로 시크
wrapper.stop()
```

### Swift Extension 사용

```swift
// 확장된 API 사용
player.playStateString  // "Playing", "Paused", "Stopped"
player.currentTime      // 현재 재생 시간
player.duration         // 전체 길이
player.volume           // 볼륨 (0-200)
player.toggleMute()     // 미uting 토글
```

### Media List 사용

```swift
let mediaList = VLCMediaList()
let listWrapper = VLCMediaListWrapper(mediaList: mediaList)

// 미디어 추가
if let url = URL(string: "https://example.com/video1.mp4") {
    listWrapper.addMedia(withURL: url)
}

// 재생
let listPlayer = VLCMediaListPlayer(mediaList: mediaList)
listPlayer.play()
listPlayer.next()
listPlayer.previous()
```

## 📱 iOS 앱 통합

### Info.plist 설정

```xml
<key>NSAppleMusicUsageDescription</key>
<string>음악 재생을 위해 접근 권한이 필요합니다</string>

<key>NSCameraUsageDescription</key>
<string>카메라 접근이 필요합니다</string>

<key>NSMicrophoneUsageDescription</key>
<string>녹음을 위해 접근 권한이 필요합니다</string>
```

### ViewController 예시

```swift
import UIKit
import MobileVLCKit

class ViewController: UIViewController {
    
    private var mediaPlayer: VLCMediaPlayerWrapper!
    private var mediaListPlayer: VLCMediaListPlayerWrapper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MediaPlayer 초기화
        mediaPlayer = VLCMediaPlayerWrapper(
            playerWithPlayer: VLCMediaPlayer()
        )
        
        // Media List 생성
        let mediaList = VLCMediaList()
        mediaListPlayer = VLCMediaListPlayerWrapper(
            listPlayer: VLCMediaListPlayer(mediaList: mediaList)
        )
        
        // 미디어 추가
        if let url = URL(string: "https://example.com/video.mp4") {
            mediaListPlayer.addMedia(withURL: url)
        }
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        mediaListPlayer.play()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        mediaPlayer.pause()
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        mediaPlayer.stop()
    }
}
```

## 🛠 빌드 방법

```bash
# SPM 으로 빌드
swift build

# 테스트 실행
swift test

# iOS 앱 빌드
xcodebuild -project MobileVLCKit.xcodeproj \
    -scheme MobileVLCKit \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build
```

## 📋 주요 클래스

### VLCKitWrapper
- 싱글톤 패턴의 메인 래퍼 클래스
- MediaPlayer 관리

### VLCMediaPlayerWrapper
- 재생 제어 (play, pause, stop)
- 시크 (seek)
- 볼륨 조절
- 재생 상태 확인

### VLCMediaWrapper
- 미디어 생성 및 관리
- 메타데이터 액세스
- MIME 타입 확인

### VLCMediaListWrapper
- 미디어 리스트 관리
- 추가/제거
- 인덱싱

### VLCMediaListPlayerWrapper
- 리스트 플레이어 제어
- 재생/일시정지/중지
- 다음/이전으로 이동

## 🔧 C API 래퍼

Swift Extension 으로 C API 를 더 쉽게 사용:

```swift
// VLCMediaPlayer 확장
player.playStateString  // String
player.currentTime      // TimeInterval
player.duration         // TimeInterval
player.volume           // Int
player.toggleMute()     // Void

// VLCMedia 확장
media.metadata          // [String: Any]
media.fileSize          // Int64
media.mimeType          // String
media.isPlayable        // Bool

// VLCMediaList 확장
list.count              // Int
list.media(at: index)   // VLCMedia?
list.allURLs            // [URL]
list.addMedia(withURL: url)
list.removeMedia(at: index)
```

## 📝 License

FiveStar AI Company 의 VLCKit 는 VLC 의 라이선스를 따릅니다.

## 📞 문의

FiveStar AI Company 홍보팀
- 개발 담당: Jasmine (자스민)
- 대표: Anton

---

🌸 **FiveStar AI Company** - Innovation & Excellence
