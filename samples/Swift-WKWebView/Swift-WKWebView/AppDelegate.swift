//
//  AppDelegate.swift
//  Swift-WKWebView
//
//  Created by Craig Rouse on 18/04/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.registerPushNotifications(application: application)
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerPushNotifications(application: UIApplication) {
        
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.delegate = self
            notificationCenter.requestAuthorization(options: [UNAuthorizationOptions.badge, UNAuthorizationOptions.sound, UNAuthorizationOptions.alert]) {_,_ in
                 DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        TealiumHelper.shared.tealium.persistentData()?.add(data: ["device_push_token": token])
        print("### Device Push Token: ###\n\n\(token)\n\n")
    }
   
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let content = response.notification.request.content
        let vcName = content.userInfo["viewController"] as? String
        if vcName == "green" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let greenViewController = storyboard.instantiateViewController(withIdentifier: "GreenViewController")

            if let window = UIApplication.shared.delegate?.window {
                window?.rootViewController?.present(greenViewController, animated: true) {}
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let vcName = content.userInfo["viewController"] as? String
        if vcName == "green" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let greenViewController = storyboard.instantiateViewController(withIdentifier: "GreenViewController")
            UIApplication.shared.delegate?.window??.rootViewController?.present(greenViewController, animated: true) {
                
            }
        }
        
        completionHandler(.sound)
    }

}

