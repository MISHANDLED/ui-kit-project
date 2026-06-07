//
//  SceneDelegate.swift
//  UIKitProject
//
//  Created by Devansh Mohata on 16/10/25.
//

import UIKit
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let viewModel = InitialViewModel()
        let viewController = InitialController(dataSource: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // Main window (tracks touches)
        //        let trackingWindow = TrackingWindow(windowScene: windowScene)
        //        trackingWindow.rootViewController = navigationController
        //        trackingWindow.makeKeyAndVisible()
        //
        //        // Overlay window (draws paths, never intercepts touches)
        //        let overlayWindow = TouchOverlayWindow(windowScene: windowScene)
        //        overlayWindow.isUserInteractionEnabled = false
        //        overlayWindow.makeKeyAndVisible()
        //
        //        // Wire them together
        //        trackingWindow.overlayWindow = overlayWindow
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        self.window = window
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let rootVC = window?.rootViewController else { return nil }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        if let nav = topVC as? UINavigationController {
            return nav.viewControllers.last
        }
        
        return topVC
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("\(#file) \(#function) \(Date())")
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        print("\(#file) \(#function) \(Date())")
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("\(#file) \(#function) \(Date())")
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("\(#file) \(#function) \(Date())")
    }
}
