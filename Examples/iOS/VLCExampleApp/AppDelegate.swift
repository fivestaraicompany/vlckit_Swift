//
//  AppDelegate.swift
//  VLCExampleApp
//
//  Application Delegate for VLCExampleApp
//

import UIKit
import MobileVLCKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mediaPlayerWrapper: VLCMediaPlayerWrapper!
    var mediaListPlayerWrapper: VLCMediaListPlayerWrapper!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
         // Create main window
        window = UIWindow(frame: UIScreen.main.bounds)
        
         // Create media player
        let player = VLCMediaPlayer()
        mediaPlayerWrapper = VLCMediaPlayerWrapper(playerWithPlayer: player)
        
         // Create media list
        let mediaList = VLCMediaList()
        mediaListPlayerWrapper = VLCMediaListPlayerWrapper(listPlayer: VLCMediaListPlayer(mediaList: mediaList))
        
         // Add sample video
        if let url = URL(string: "https://www.w3schools.com/html/mov_bbb.mp4") {
            let media = VLCMedia(url: url)
            mediaList.addMedia(media)
        }
        
         // Create root view controller
        let viewController = ViewController()
        viewController.mediaPlayerWrapper = mediaPlayerWrapper
        viewController.mediaListPlayerWrapper = mediaListPlayerWrapper
        
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
         // Sent when the application is about to move from active to inactive state.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
         // Use this method to release shared resources.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
         // Called as part of the transition from the background to the active state.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
         // Restart any tasks that were paused (or not yet started) while the application was inactive.
    }

    deinit {
        mediaPlayerWrapper.stop()
    }
}
