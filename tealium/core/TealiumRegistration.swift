//
//  TealiumRegistration.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/17/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
import UserNotifications
#endif

public protocol TealiumRegistration {
    func registerPushToken(_ token: String)
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
}
