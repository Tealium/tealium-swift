//
//  TealiumHelper.swift
//  WatchPuzzle
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation

extension String: Error {
}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
class TealiumHelper: NSObject {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = false

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                profile: "demo",
                environment: "dev",
                datasource: "test12",
                optionalData: nil)
        // OPTIONALLY set log level
        config.setLogLevel(logLevel: .verbose)
        config.setConsentLoggingEnabled(true)
        // Example: set initial consent categories - only used on first launch
        // let consentCat: [TealiumConsentCategories] = [.bigData, .analytics, .cookieMatch]
        // config.setInitialUserConsentCategories(consentCat)
        // Example: change default behavior to notConsented. Prevents library queueing requests before consent granted
        // config.setInitialUserConsentStatus(.notConsented)
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        // disable autotracking
        let list = TealiumModulesList(isWhitelist:false, moduleNames: ["autotracking"])
        config.setModulesList(list)
        // REQUIRED Initialization
        self.tealium = Tealium(config: config) { _ in
                    // Interact with Tealium inside callback to guarantee successful initialization
                    
                    self.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
                    self.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])
                    self.tealium?.consentManager()?.addConsentDelegate(self)
                }
    }

    func resetConsentPreferences() {
        tealium?.consentManager()?.resetUserConsentPreferences()
    }

    func updateConsentPreferences(_ dict: [String: Any]) {
        if let status = dict["consentStatus"] as? String {
            var tealiumConsentCategories = [TealiumConsentCategories]()
            let tealiumConsentStatus = (status == "consented") ? TealiumConsentStatus.consented : TealiumConsentStatus.notConsented
            if let categories = dict["consentCategories"] as? [String] {
                tealiumConsentCategories = TealiumConsentCategories.consentCategoriesStringArrayToEnum(categories)
            }
            self.tealium?.consentManager()?.setUserConsentStatusWithCategories(status: tealiumConsentStatus, categories: tealiumConsentCategories)
        }
    }

    func simpleConsent(_ dict: [String: Any]) {
        if let status = dict["consentStatus"] as? String {
            let tealiumConsentStatus = (status == "consented") ? TealiumConsentStatus.consented : TealiumConsentStatus.notConsented
            self.tealium?.consentManager()?.setUserConsentStatus(tealiumConsentStatus)
        }
    }

    func getCurrentConsentPreferences() -> [String: Any]? {
        return self.tealium?.consentManager()?.getUserConsentPreferences()?.toDictionary()
    }

    func track(title: String, data: [String: Any]?) {
        tealium?.track(title: title,
                data: data,
                completion: { (success, info, error) in
                    // Optional post processing
                    if self.enableHelperLogs == false {
                        return
                    }
                    print("*** TealiumHelper: track completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")
                })
    }

    func trackView(title: String, data: [String: Any]?) {
        tealium?.track(title: title,
                data: data,
                completion: { (success, info, error) in
                    // Optional post processing
                    if self.enableHelperLogs == false {
                        return
                    }
                    // Alternatively, monitoring track completions can be done here vs. using the delegate module's callbacks.
                    print("*** TealiumHelper: view completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")
                })
    }

    func crash() {
        NSException.raise(NSExceptionName(rawValue: "Exception"), format: "This is a test exception", arguments: getVaList(["nil"]))
    }
}

extension TealiumHelper: TealiumDelegate {

    func tealiumShouldTrack(data: [String: Any]) -> Bool {
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        if enableHelperLogs == false {
            return
        }
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))" : "")")
    }
}

// MARK: Consent Delegate
extension TealiumHelper: TealiumConsentManagerDelegate {

    func willDropTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call DROPPED ******")
        print(request.data)
    }

    func willQueueTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call Queued ******")
        print(request.data)
    }

    func willSendTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call Sent ******")
        print(request.data)
    }

    func consentStatusChanged(_ status: TealiumConsentStatus) {
        print(status)
    }

    func userConsentedToTracking() {
        print("User Consented")
    }

    func userOptedOutOfTracking() {
        print("User Declined Tracking")
    }

    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {
        print("Categories Changed")
    }
}
