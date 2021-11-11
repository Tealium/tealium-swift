//
//  AutoTrackingTvOSTestApp.swift
//  AutoTrackingTvOSTest
//
//  Created by Enrico Zannini on 15/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI

@main
struct AutoTrackingTvOSTestApp: App {
    
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
}
