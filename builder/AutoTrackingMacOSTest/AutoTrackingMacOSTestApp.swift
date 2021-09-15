//
//  AutoTrackingMacOSTestApp.swift
//  AutoTrackingMacOSTest
//
//  Created by Enrico Zannini on 14/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import SwiftUI


@main
struct AutoTrackingMacOSTestApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                ContentView()
                TextContent(model: TrackViewModel())
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        TealiumHelper.shared.start()
    }
}
