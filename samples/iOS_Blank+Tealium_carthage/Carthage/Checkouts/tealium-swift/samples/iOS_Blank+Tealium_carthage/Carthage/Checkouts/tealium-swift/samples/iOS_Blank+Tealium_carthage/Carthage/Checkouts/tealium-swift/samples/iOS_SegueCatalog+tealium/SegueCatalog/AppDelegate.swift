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
        
//        TealiumHelper.sharedInstance().start()
//        
//        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(detected),
//                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
//                                               object: nil)
//        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(detected),
//                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
//                                               object: nil)
        
//        let config = TealiumConfig(account: "services-crouse",
//                                   profile: "mobile",
//                                   environment: "dev")
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev")
//        let list = TealiumModulesList(isWhitelist: true,
//                                      moduleNames: ["Logger",
//                                                    //"Lifecycle",
////                                        "Async",
////                                         "Autotracking",
//                                        // "FileStorage",
//                                        "Attribution",
//                                        "AppData",
//                                        // "Datasource",
//                                        "PersistentData",
//                                        "VolatileData",
//                                        "Delegate",
//                                        "Connectivity",
//                                        "Collect",
////                                        "TagManagement",
//                                        "RemoteCommands"
//            ])
//        config.setModulesList(list)
        tealium = Tealium(config: config)
        tealium?.track(title: "appDidFinishLaunching")
        
    }
    
    func detected(n : NSNotification){
        print("*** AppDelegate: detected: Wake or sleep detected.")
    }
}
