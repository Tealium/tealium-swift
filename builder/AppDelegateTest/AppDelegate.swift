//
//  AppDelegate.swift
//  AppDelegateTest
//
//  Created by Enrico Zannini on 21/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TealiumHelper.shared.start()
        // Override point for customization after application launch.
        return true
    }

}

