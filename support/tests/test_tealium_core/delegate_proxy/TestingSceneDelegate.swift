//
//  TestingSceneDelegate.swift
//  TealiumAppDelegateProxyTests-iOS
//
//  Created by Christina Schell on 4/16/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import UIKit

class TestingSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

//        window = UIWindow(windowScene: windowScene)
//        window?.rootViewController = TestingRootViewController()
//        window?.makeKeyAndVisible()
    }
}
