//
//  TestingAppDelegate.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import UIKit
import TealiumCore
import TealiumCollect

@objc(TestingAppDelegate)
final class TestingAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var appDelegateTealium: Tealium?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 13, *) {

            
            // Remove any cached scene configurations to ensure that TestingAppDelegate.application(_:configurationForConnecting:options:) is called and TestingSceneDelegate will be used when running unit tests. NOTE: THIS IS PRIVATE API AND MAY BREAK IN THE FUTURE!
            for sceneSession in application.openSessions {
                application.perform(Selector(("_removeSessionFromSessionSet:")), with: sceneSession)
            }
            
            let config = TealiumConfig(account: "tealiummobile", profile: "test", environment: "dev")
            //AppDelegateProxyTests.testNumber += 1
            config.logLevel = .silent
            config.dispatchers = [Dispatchers.Collect]
            config.batchingEnabled = false
            TestingAppDelegate.appDelegateTealium = Tealium(config: config, dataLayer: DummyDataManagerTestAppDelegate(), modulesManager: nil) { _ in
                            }

            
        } else {
            window = UIWindow()
            window?.rootViewController = TestingRootViewController()
            window?.makeKeyAndVisible()
        }

        return true
    }

    // MARK: UISceneSession Lifecycle
    @available(iOS 13, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = TestingSceneDelegate.self
        sceneConfiguration.storyboard = nil

        return sceneConfiguration
    }
}

class DummyDataManagerTestAppDelegate: DataLayerManagerProtocol {
    var traceId: String? {
        willSet {
            all["cp.trace_id"] = newValue
        }
    }

    var all: [String: Any] = [:]

    var allSessionData: [String: Any] = [:]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = [:]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: TealiumConfig(account: "account", profile: "profile", environment: "env"))

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry?) {

    }

    func add(key: String, value: Any, expiry: Expiry?) {
        switch expiry {
        case .session:
            all[key] = value
            return
        default:
            break;
        }
    }

    func joinTrace(id: String) {
        traceId = id
    }

    func delete(for Keys: [String]) {

    }

    func delete(for key: String) {

    }

    func deleteAll() {
        all.removeAll()
    }

    func leaveTrace() {

    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}
