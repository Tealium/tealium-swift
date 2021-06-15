//
//  TealiumHelper.swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
    static let dataSourceKey = "abc123"
}

// Change this to false to disable all the Tealium logs
let enableHelperLogs = true

public enum WebViewExampleType: Equatable {
    case noUtag // example webview without utag
    case withUtag // example webview with mobile.html/utag.js
}

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
                               profile: TealiumConfiguration.profile,
                               environment: TealiumConfiguration.environment,
                               dataSource: TealiumConfiguration.dataSourceKey)

    var tealium: Tealium?

    // set this to change the example that loads - JSInterfaceExample
    public var exampleType: WebViewExampleType = .withUtag

    // MARK: Tealium Initilization
    private init() {
        // Optional Config Settings
        if enableHelperLogs { config.logLevel = .info }

        config.shouldUseRemotePublishSettings = false
        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self
        config.consentLoggingEnabled = true
        config.consentPolicy = .ccpa
        config.hostedDataLayerKeys = ["hdl-test": "product_id"]
        config.timedEventTriggers = [TimedEventTrigger(start: "product_view", end: "order_complete"),
                                     TimedEventTrigger(start: "start_game", end: "buy_coins")]

        #if os(iOS)
        // Add dispatchers
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.RemoteCommands]
        #else
        config.dispatchers = [Dispatchers.Collect]
        #endif

        // Add collectors
        #if os(iOS) && targetEnvironment(macCatalyst)
        config.collectors = [Collectors.VisitorService]
        #elseif os(iOS) && !targetEnvironment(macCatalyst)
        config.collectors = [Collectors.Attribution, Collectors.VisitorService, Collectors.Location]

         // Batching:
         config.batchingEnabled = false // true to enable

        // Location - Geofence Monitoring:
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        config.useHighAccuracy = true
        config.updateDistance = 200.0
        
        // SKAdNetwork event handling
        config.searchAdsEnabled = true
        config.skAdAttributionEnabled = true
        config.skAdConversionKeys = ["conversion_event": "conversion_value"]

        // Remote Commands:
        let remoteCommand = RemoteCommand(commandId: "hello", description: "world") { response in
            guard let payload = response.payload else {
                return
            }
            // Do something w/remote command payload
            if enableHelperLogs {
                print(payload)
            }
        }
        config.addRemoteCommand(remoteCommand)
        #endif

        tealium = Tealium(config: config) { _ in
            // Optional post init processing
            self.tealium?.dataLayer.add(data: ["somekey": "someval"], expiry: .afterCustom((.months, 1)))
            self.tealium?.dataLayer.add(key: "someotherkey", value: "someotherval", expiry: .forever)
            #if os(iOS) && !targetEnvironment(macCatalyst)
            // Location - Request Auth:
            self.tealium?.location?.requestAuthorization()
            // Once appropriate and if needed, you can use a Tealium helper method to request temporary full accuracy (in iOS 14)
            // Simulating time passing after initial auth is given, not needed otherwise
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if #available(iOS 14, *) {
                    self.tealium?.location?.requestTemporaryFullAccuracyAuthorization(purposeKey: "NearStore") // key must match what is in Info.plist
                }
            }
            #endif
        }

    }

    public func start() {
        _ = TealiumHelper.shared
    }

    func resetConsentPreferences() {
        tealium?.consentManager?.resetUserConsentPreferences()
    }

    func toggleConsentStatus() {
        if let consentStatus = tealium?.consentManager?.userConsentStatus {
            switch consentStatus {
            case .notConsented:
                TealiumHelper.shared.tealium?.consentManager?.userConsentCategories = [.affiliates, .analytics, .bigData]
            case .unknown:
                TealiumHelper.shared.tealium?.consentManager?.userConsentStatus = .consented
            default:
                TealiumHelper.shared.tealium?.consentManager?.userConsentStatus = .notConsented
            }
        }
    }

    func track(title: String, data: [String: Any]?) {
        let dispatch = TealiumEvent(title, dataLayer: data)
        tealium?.track(dispatch)
    }

    func trackView(title: String, data: [String: Any]?) {
        let dispatch = TealiumView(title, dataLayer: data)
        tealium?.track(dispatch)
    }

    func joinTrace(_ traceID: String) {
        self.tealium?.joinTrace(id: traceID)
    }

    func leaveTrace() {
        self.tealium?.leaveTrace()
    }
}

// MARK: Visitor Service Module Delegate
extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile),
           let string = String(data: json, encoding: .utf8) {
            if enableHelperLogs {
                print(string)
            }
        }
    }
}
