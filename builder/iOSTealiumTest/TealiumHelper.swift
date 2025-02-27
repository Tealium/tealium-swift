//
//  TealiumHelper.swift
//  iOSTealiumTest
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumAutotracking
import TealiumCollect
import TealiumCore
import TealiumInAppPurchase
import TealiumLifecycle
import TealiumMomentsAPI
import TealiumVisitorService

#if os(iOS)
    import WebKit
    import TealiumAttribution
    import TealiumLocation
    import TealiumRemoteCommands
    import TealiumTagManagement
#endif

extension TealiumDataKey {
    static let email = "email"
}

class TealiumHelper: ObservableObject {

    @ToAnyObservable(TealiumBufferedSubject(bufferSize: 10))
    var onWillTrack: TealiumObservable<[String: Any]>
    @Published var visitorProfile: TealiumVisitorProfile?
    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = true

    private init() {}

    func start() {
        let config = TealiumConfig(
            account: "tealiummobile",
            profile: "demo",
            environment: "prod",
            dataSource: "test12",
            options: nil)

        config.connectivityRefreshInterval = 5
        config.loggerType = .os
        config.logLevel = .debug
        config.consentPolicy = .gdpr
        config.consentLoggingEnabled = true
        //        config.remoteHTTPCommandDisabled = false
        config.dispatchListeners = [self]
        config.dispatchValidators = [self]
        config.shouldUseRemotePublishSettings = false
        // config.batchingEnabled = true
        // config.batchSize = 5
        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self
        config.memoryReportingEnabled = true
        config.autoTrackingCollectorDelegate = self
        config.batterySaverEnabled = true
        config.hostedDataLayerKeys = ["hdl-test": "product_id"]
        config.timedEventTriggers = [
            TimedEventTrigger(start: "product_view", end: "order_complete"),
            TimedEventTrigger(start: "start_game", end: "buy_coins"),
        ]

        config.consentExpiry = (time: 2, unit: .years)
        config.onConsentExpiration = {
            print("Consent expired")
        }
        config.visitorIdentityKey = TealiumDataKey.email
        config.visitorServiceRefresh = .every(1, .minutes)
        #if os(iOS)
            config.enableBackgroundLocation = true
            config.collectors = [
                Collectors.Attribution,
                Collectors.Lifecycle,
                Collectors.Connectivity,
                Collectors.Device,
                Collectors.Location,
                Collectors.MomentsAPI,
                Collectors.VisitorService,
                Collectors.InAppPurchase,
                Collectors.AutoTracking,
            ]

            config.dispatchers = [
                Dispatchers.Collect,
                //                Dispatchers.TagManagement,
                Dispatchers.RemoteCommands,
            ]

            // config.appDelegateProxyEnabled = false
            config.remoteAPIEnabled = true
            config.remoteCommandConfigRefresh = .every(24, .hours)
            config.searchAdsEnabled = true
            config.skAdAttributionEnabled = true
            config.skAdConversionKeys = ["conversion_event": "conversion_value"]
            config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
            config.desiredAccuracy = .best
            config.updateDistance = 100.0
            config.momentsAPIRegion = .us_east
        #else
            config.collectors = [
                Collectors.Lifecycle,
                Collectors.AppData,
                Collectors.Connectivity,
                Collectors.Device,
                Collectors.VisitorService,
                Collectors.AutoTracking,
                Collectors.InAppPurchase,
            ]
            config.dispatchers = [
                Dispatchers.Collect
            ]
        #endif
        tealium = Tealium(config: config) { [weak self] response in
            guard let self = self,
                let teal = self.tealium
            else {
                return
            }

            let dataLayer = teal.dataLayer
            teal.consentManager?.userConsentStatus = .consented
            dataLayer.add(key: "myvarforever", value: 123_456, expiry: .forever)
            dataLayer.add(data: ["some_key1": "some_val1"], expiry: .session)
            dataLayer.add(data: ["some_key_forever": "some_val_forever"], expiry: .forever)  // forever
            dataLayer.add(data: ["until": "restart"], expiry: .untilRestart)
            dataLayer.add(data: ["custom": "expire in 3 min"], expiry: .afterCustom((.minutes, 3)))

            #if os(iOS)
                teal.location?.requestAuthorization()

                guard let remoteCommands = self.tealium?.remoteCommands else {
                    return
                }

                teal.getTagManagementWebView { webView in
                    if #available(iOS 16.4, *) {
                        //                    webView.isInspectable = true // Uncomment to inspect tagManagement webviews on XCode 14.3+ and iOS 16.4+
                    }
                }
                let display = RemoteCommand(commandId: "display", description: "Test") { response in
                    guard let payload = response.payload,
                        let hello = payload["hello"] as? String,
                        let key = payload["key"] as? String,
                        let tealium = payload["tealium"] as? String
                    else {
                        return
                    }
                    print(
                        "Remote Command data: hello = \(hello), key = \(key), tealium = \(tealium) 🎉🎊"
                    )
                }
                remoteCommands.add(display)
            #endif
        }
    }

    func resetConsentPreferences() {
        tealium?.consentManager?.resetUserConsentPreferences()
    }

    func toggleConsentStatus() {
        if let consentStatus = tealium?.consentManager?.userConsentStatus {
            switch consentStatus {
            case .notConsented:
                TealiumHelper.shared.tealium?.consentManager?.userConsentCategories = [
                    .affiliates, .analytics, .bigData,
                ]
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

    func fetchMoments(engineId: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
        // example showing all the different types of attributes
        tealium?.momentsAPI?.fetchEngineResponse(
            engineID: engineId,
            completion: { engineResponse in
                switch engineResponse {
                case .success(let engineResponse):
                    print(
                        "Moments fetched successfully - String attributes:", engineResponse.strings ?? [])
                    print(
                        "Moments fetched successfully - Boolean attributes:",
                        engineResponse.booleans ?? [])
                    print("Moments fetched successfully - Audiences:", engineResponse.audiences ?? [])
                    print("Moments fetched successfully - Date attributes:", engineResponse.dates ?? [String: Int64]())
                    print("Moments fetched successfully - Badges:", engineResponse.badges ?? [])
                    print("Moments fetched successfully - Numbers:", engineResponse.numbers ?? [String: Double]())
                case .failure(let error):
                    print("Error fetching moments:", error.localizedDescription)
                    if let suggestion = (error as? LocalizedError)?.recoverySuggestion {
                        print("Recovery suggestion:", suggestion)
                    }
                }
                completion(engineResponse)
            })
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

    func crash() {
        NSException.raise(
            NSExceptionName(rawValue: "Exception"), format: "This is a test exception",
            arguments: getVaList(["nil"]))
    }

}

extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        DispatchQueue.main.async {
            self.visitorProfile = visitorProfile
        }
        if let json = try? JSONEncoder().encode(visitorProfile),
            let string = String(data: json, encoding: .utf8)
        {
            if self.enableHelperLogs {
                print("Visitor Profile: \(string)")
            }
        }
    }
}

extension TealiumHelper: DispatchListener {
    public func willTrack(request: TealiumRequest) {
        if let request = request as? TealiumTrackRequest {
            _onWillTrack.publish(request.trackDictionary)
        }
        if self.enableHelperLogs {
            print("helper - willtrack")
        }
    }
}

extension TealiumHelper: DispatchValidator {

    var id: String {
        return "Helper"
    }

    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        (false, nil)
    }

    func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }

    func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }
}

extension TealiumHelper: AutoTrackingDelegate {
    func onCollectScreenView(screenName: String) -> [String: Any] {
        return ["from_delegate": "true"]
    }
}

class MyDateCollector: Collector {

    var id = "MyDateCollector"

    var data: [String: Any]? {
        ["day_of_week": dayOfWeek]
    }

    var config: TealiumConfig

    required init(
        context: TealiumContext,
        delegate: ModuleDelegate?,
        diskStorage: TealiumDiskStorageProtocol?,
        completion: ((Result<Bool, Error>, [String: Any]?)) -> Void
    ) {
        self.config = context.config
    }

    var dayOfWeek: String {
        return "\(Calendar.current.dateComponents([.weekday], from: Date()).weekday ?? -1)"
    }
}

class MyCustomDispatcher: Dispatcher {

    var id = "MyCustomDispatcher"

    var config: TealiumConfig

    required init(context: TealiumContext, delegate: ModuleDelegate, completion: ModuleCompletion?)
    {
        self.config = context.config
    }

    func dynamicTrack(_ request: TealiumRequest, completion: ModuleCompletion?) {
        switch request {
        case let request as TealiumTrackRequest:
            if TealiumHelper.shared.enableHelperLogs {
                print("Track received: \(request.event ?? "no event name")")
            }
        // perform track action, e.g. send to custom endpoint
        case _ as TealiumBatchTrackRequest:
            if TealiumHelper.shared.enableHelperLogs {
                print("Batch track received")
            }
        // perform batch track action, e.g. send to custom endpoint
        default:
            return
        }
    }
}
