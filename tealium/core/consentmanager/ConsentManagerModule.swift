//
//  ConsentManagerModule.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

class ConsentManagerModule: Collector, DispatchValidator {

    public let id: String = ModuleNames.consentmanager
    var config: TealiumConfig
    var consentManager: ConsentManager?
    weak var delegate: ModuleDelegate?
    var dataLayer: DataLayerManagerProtocol?
    var diskStorage: TealiumDiskStorageProtocol!

    var data: [String: Any]? {
        consentManager?.currentPolicy.consentPolicyStatusInfo
    }

    required init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  completion: ModuleCompletion) {
        self.config = context.config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config,
                                                             forModule: ConsentKey.moduleName,
                                                             isCritical: true)
        self.dataLayer = context.dataLayer
        self.delegate = delegate
        consentManager = ConsentManager(config: config, delegate: delegate, diskStorage: self.diskStorage, dataLayer: self.dataLayer)
        completion((.success(true), nil))
    }

    func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        guard newConfig.consentPolicy != nil else {
            consentManager = nil
            return
        }
        if newConfig != self.config,
           newConfig.account != config.account,
           newConfig.profile != config.profile {
            self.diskStorage = TealiumDiskStorage(config: request.config, forModule: ConsentKey.moduleName, isCritical: true)
            consentManager = ConsentManager(config: config, delegate: delegate, diskStorage: self.diskStorage, dataLayer: self.dataLayer)
        }
        config = newConfig
    }

    /// Determines whether or not a request should be queued based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `(Bool, [String: Any]?)` true/false if should be queued, then the resulting dictionary of consent data.
    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        guard let request = request as? TealiumTrackRequest else {
            return (true, [TealiumKey.queueReason: TealiumKey.batchingEnabled])
        }

        // allow tracking calls to continue if they are for auditing purposes
        if let event = request.trackDictionary[TealiumKey.event] as? String,
           (event == ConsentKey.consentPartialEventName ||
                event == ConsentKey.consentGrantedEventName ||
                event == ConsentKey.consentDeclinedEventName ||
                event == ConsentKey.gdprConsentCookieEventName ||
                event == ConsentKey.ccpaCookieEventName) {
            return (false, nil)
        }
        switch consentManager?.trackingStatus {
        case .trackingQueued:
            var newData = request.trackDictionary
            newData[TealiumKey.queueReason] = ConsentKey.moduleName
            let newTrack = TealiumTrackRequest(data: newData)
            return (true, addConsentDataToTrack(newTrack).trackDictionary)
        case .trackingAllowed:
            return (false, addConsentDataToTrack(request).trackDictionary)
        case .trackingForbidden:
            return (false, addConsentDataToTrack(request).trackDictionary)
        case .none:
            return (false, nil)
        }
    }

    /// Determines whether or not a request should be dropped based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `Bool` true/false if should be dropped.
    func shouldDrop(request: TealiumRequest) -> Bool {
        consentManager?.trackingStatus == .trackingForbidden
    }

    /// Determines whether or not a request should be purged based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `Bool` true/false if should be purged.
    func shouldPurge(request: TealiumRequest) -> Bool {
        consentManager?.trackingStatus == .trackingForbidden
    }

    /// Adds consent categories and status to the tracking request.￼
    ///
    /// - Parameter track: `TealiumTrackRequest` to be modified
    func addConsentDataToTrack(_ track: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = track.trackDictionary
        if let consentDictionary = consentManager?.currentPolicy.consentPolicyStatusInfo {
            newTrack += consentDictionary
        }
        return TealiumTrackRequest(data: newTrack)
    }

}
