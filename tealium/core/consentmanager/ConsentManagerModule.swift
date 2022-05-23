//
//  ConsentManagerModule.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

enum IABTCFKeys {
    static let tcfString = "IABTCF_TCString"
    static let cmpId = "IABTCF_CmpSdkID"
    static let vendorConsents = "IABTCF_VendorConsents"
    static let purposeConsents = "IABTCF_PurposeConsents"
}
var contextPointer = 1
class ConsentManagerModule: NSObject, DispatchValidator {

    public let id: String = ModuleNames.consentmanager
    var config: TealiumConfig
    var consentManager: ConsentManager?
    weak var delegate: ModuleDelegate?
    var dataLayer: DataLayerManagerProtocol?
    var diskStorage: TealiumDiskStorageProtocol

    required init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  completion: ModuleCompletion) {
        self.config = context.config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: context.config,
                                                             forModule: ConsentKey.moduleName,
                                                             isCritical: true)
        self.dataLayer = context.dataLayer
        self.delegate = delegate
        super.init()
        expireConsent()
        consentManager = ConsentManager(config: config, delegate: delegate, diskStorage: self.diskStorage, dataLayer: self.dataLayer)
        completion((.success(true), nil))
        
        UserDefaults.standard.addObserver(self, forKeyPath: IABTCFKeys.tcfString, options: NSKeyValueObservingOptions.new, context: &contextPointer)
        
        let a = UserDefaults.standard.string(forKey: IABTCFKeys.tcfString)
        print(a)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &contextPointer else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        print("caspiooooo", keyPath, object)
    }

    /// Determines whether or not a request should be queued based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `(Bool, [String: Any]?)` true/false if should be queued, then the resulting dictionary of consent data.
    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        if let _ = request as? TealiumBatchTrackRequest {
            return (true, [TealiumDataKey.queueReason: TealiumConfigKey.batchingEnabled])
        }
        guard let request = request as? TealiumTrackRequest else {
            return (false, nil) // Should never happen
        }
        expireConsent()
        var consentData = getConsentData()
        if request.containsAuditEvent {
            return (false, consentData)
        }

        switch consentManager?.trackingStatus {
        case .trackingQueued:
            consentData[TealiumDataKey.queueReason] = ConsentKey.moduleName
            return (true, consentData)
        case .trackingAllowed:
            return (false, consentData)
        case .trackingForbidden:
            return (false, consentData)
        case .none:
            return (false, nil)
        }
    }

    /// Determines whether or not a request should be dropped based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `Bool` true/false if should be dropped.
    func shouldDrop(request: TealiumRequest) -> Bool {
        guard let request = request as? TealiumTrackRequest else {
            return true
        }
        if request.containsAuditEvent {
            return false
        }
        return consentManager?.trackingStatus == .trackingForbidden
    }

    /// Determines whether or not a request should be purged based on a user's consent preferences selection.
    /// - Parameter request: incoming `TealiumRequest`
    /// - Returns: `Bool` true/false if should be purged.
    func shouldPurge(request: TealiumRequest) -> Bool {
        guard let request = request as? TealiumTrackRequest else {
            return true
        }
        if request.containsAuditEvent {
            return false
        }
        return consentManager?.trackingStatus == .trackingForbidden
    }

    func getConsentData() -> [String: Any] {
        if let consentDictionary = consentManager?.currentPolicy.policyTrackingData {
            return consentDictionary
        }
        return [:]
    }

    /// Checks if the consent selections are expired
    /// If so, resets consent preferences and triggers optional callback
    public func expireConsent() {
        guard let consentManager = consentManager else {
            return
        }
        let expiry = config.consentExpiry ?? consentManager.currentPolicy.defaultConsentExpiry
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(-expiry.time, for: expiry.unit.component)
        guard let lastSet = consentManager.lastConsentUpdate,
              let expiryDate = Calendar(identifier: .gregorian).date(byAdding: components, to: Date()),
              expiryDate > lastSet else {
            return
        }
        consentManager.userConsentStatus = .unknown
        guard let callback = consentManager.onConsentExpiraiton else {
            return
        }
        callback()
    }

}

fileprivate extension TealiumTrackRequest {
    // allow tracking calls to continue if they are for auditing purposes
    var containsAuditEvent: Bool {
        if let event = self.trackDictionary[TealiumDataKey.event] as? String,
           (event == ConsentKey.consentPartialEventName ||
                event == ConsentKey.consentGrantedEventName ||
                event == ConsentKey.consentDeclinedEventName ||
                event == ConsentKey.gdprConsentCookieEventName ||
                event == ConsentKey.ccpaCookieEventName) {
            return true
        }
        return false
    }
}
