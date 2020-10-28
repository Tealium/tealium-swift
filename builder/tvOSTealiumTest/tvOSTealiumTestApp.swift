//
//  tvOSTealiumTestApp.swift
//  tvOSTealiumTest
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import SwiftUI

@main
struct tvOSTealiumTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TealiumHelper.shared.start()
        return true
    }
}
