import UIKit
import MobileVLCKit

class ViewController: UIViewController {
    
    private var mediaPlayer: VLCMediaPlayer?
    private var media: VLCMedia?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMediaPlayer()
    }
    
    private func setupMediaPlayer() {
        guard let library = VLCLibrary.sharedLibrary else { return }
        
        let player = VLCMediaPlayer(library: library)
        self.mediaPlayer = player
        
        if let player = player {
            player.delegate = self
            player.videoView = view
        }
    }
}

extension ViewController: VLCMediaPlayerDelegate {
    
    func mediaPlayerTimeChanged(_ notification: Notification) {
        print("Time changed: \(notification)")
    }
    
    func mediaPlayerStateChanged(_ notification: Notification) {
        if let player = notification.object as? VLCMediaPlayer {
            print("Player state: \(player.state)")
        }
    }
    
    func mediaPlayerTitleChanged(_ notification: Notification) {
        print("Title changed: \(notification)")
    }
    
    func mediaPlayerChapterChanged(_ notification: Notification) {
        print("Chapter changed: \(notification)")
    }
    
    func mediaPlayerLoudnessChanged(_ loudness: VLCMediaLoudness) {
        print("Loudness changed: \(loudness.loudnessValue)")
    }
    
    func mediaPlayerSnapshot(_ fileName: String) {
        print("Snapshot taken: \(fileName)")
    }
    
    func mediaPlayerStartedRecording(_ mediaPlayer: VLCMediaPlayer) {
        print("Recording started")
    }
    
    func mediaPlayer(_ mediaPlayer: VLCMediaPlayer, recordingStoppedAtPath path: String) {
        print("Recording stopped at: \(path)")
    }
}
