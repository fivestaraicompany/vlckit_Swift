//
//  ViewController.swift
//  VLCExampleApp
//
//  Example iOS app using VLCKit Swift Wrapper
//

import UIKit
import MobileVLCKit

class ViewController: UIViewController {
    
    private var mediaPlayerWrapper: VLCMediaPlayerWrapper!
    private var mediaListWrapper: VLCMediaListWrapper!
    private var mediaListPlayerWrapper: VLCMediaListPlayerWrapper!
    
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMediaPlayer()
        setupMediaList()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func setupMediaPlayer() {
        mediaPlayerWrapper = VLCMediaPlayerWrapper(playerWithPlayer: VLCMediaPlayer())
    }
    
    private func setupMediaList() {
        let mediaList = VLCMediaList()
        mediaListWrapper = VLCMediaListWrapper(mediaList: mediaList)
        
        // Add sample videos
        if let videoURL = URL(string: "https://www.w3schools.com/html/mov_bbb.mp4") {
            mediaListWrapper.addMediaWithURL:videoURL)
        }
        
        mediaListPlayerWrapper = VLCMediaListPlayerWrapper(listPlayer: VLCMediaListPlayer(mediaList: mediaList))
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        mediaListPlayerWrapper.play()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        mediaPlayerWrapper.pause()
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        mediaPlayerWrapper.stop()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaListWrapper.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Video \(indexPath.item + 1)"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mediaListPlayerWrapper.stop()
        mediaListPlayerWrapper.seek(to: indexPath.row)
        mediaListPlayerWrapper.play()
    }
}
