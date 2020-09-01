//
//  TealiumRegistration.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/17/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import UIKit
import UserNotifications

public protocol TealiumApplication { }
extension UIApplication: TealiumApplication { }

public protocol TealiumRegistration {

    func registerPushToken(_ token: String)

    func application(_ application: TealiumApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)

    // Optional
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)

    // Optional
    func pushAuthorization(fromUserNotificationCenter: Bool)
}

public protocol TealiumDeepLinkable {
    func application(_ application: TealiumApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
}

public extension TealiumRegistration {

    func pushAuthorization(fromUserNotificationCenter: Bool) { }
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) { }

}
#endif
