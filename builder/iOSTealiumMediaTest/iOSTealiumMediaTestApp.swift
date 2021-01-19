//
//  iOSTealiumMediaTestApp.swift
//  iOSTealiumMediaTest
//
//  Created by Christina S on 1/14/21.
//

import SwiftUI

@main
struct iOSTealiumMediaTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            TealiumHelper.shared.start()
            return true
        }
}
