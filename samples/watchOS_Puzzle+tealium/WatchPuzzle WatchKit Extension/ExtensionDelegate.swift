/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The WatchOS implementation of the app extension delegate.
 */

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidBecomeActive() {
                
        TealiumHelper.sharedInstance().track(title: "testLaunch",
                                             data: ["gameStatus":"started" as AnyObject])
    }
}
