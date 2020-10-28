//
//  AppDelegate.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit

var tealiumTraceId = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if compiler(>=5.1)
        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            window?.overrideUserInterfaceStyle = .light
        }
        #endif

        TealiumHelper.shared.start()
        TealiumHelper.joinTrace(id: tealiumTraceId)

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) {
        TealiumHelper.killTrace(traceId: tealiumTraceId)
    }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }

}
