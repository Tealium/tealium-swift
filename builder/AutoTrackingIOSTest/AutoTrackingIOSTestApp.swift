//
//  AutoTrackingIOSTestApp.swift
//  AutoTrackingIOSTest
//
//  Created by Enrico Zannini on 26/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI

@main
struct AutoTrackingIOSTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                ContentView()
                TextContent(model: TrackViewModel())
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        TealiumHelper.shared.start()
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    // For AppDelegateProxyTests
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
    }
}
