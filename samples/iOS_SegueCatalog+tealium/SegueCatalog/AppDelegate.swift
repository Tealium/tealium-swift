/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Main application entry point.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Properties
    
    var window: UIWindow?
    var tealium: Tealium?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        
        TealiumHelper.sharedInstance().start()
        
        print("Bundle: \(Bundle.main.infoDictionary)")
    }

}
