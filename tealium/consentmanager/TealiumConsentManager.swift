//
//  TealiumConsentManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/29/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

public class TealiumConsentManager {

    private var consentDelegates = TealiumMulticastDelegate<TealiumConsentManagerDelegate>()
    private weak var moduleDelegate: TealiumModuleDelegate?
    private var tealiumConfig: TealiumConfig?
    private var consentUserPreferences: TealiumConsentUserPreferences?
    private let consentPreferencesStorage = TealiumConsentPreferencesStorage()
    var consentLoggingEnabled = false
    var consentManagerModuleInstance: TealiumConsentManagerModule?

    /// Initialize consent manager
    ///
    /// - Parameters:
    /// - config: TealiumConfig
    /// - delegate: TealiumModuleDelegate?
    /// - completion: Optional completion block, called when fully initialized
    public func start(config: TealiumConfig, delegate: TealiumModuleDelegate?, _ completion: (() -> Void)?) {
        tealiumConfig = config
        consentLoggingEnabled = config.isConsentLoggingEnabled()
        moduleDelegate = delegate
        // try to load config from UserDefaults first
        if let preferences = getSavedPreferences() {
            consentUserPreferences = preferences
            // always need to update the consent cookie in TiQ, so this will trigger update_consent_cookie
            trackUserConsentPreferences(preferences: consentUserPreferences)
        } else if tealiumConfig?.getInitialUserConsentStatus() != nil || tealiumConfig?.getInitialUserConsentCategories() != nil {
            updateConsentPreferencesFromConfig(tealiumConfig)
        } else {
            // not yet determined state.
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: .unknown, consentCategories: nil)
        }
        completion?()
    }

    /// Sets the module delegate
    ///
    /// - Parameter delegate: TealiumModuleDelegate
    public func setModuleDelegate(delegate: TealiumModuleDelegate) {
        moduleDelegate = delegate
    }

    /// Updates current consent preferences from config passed at init time
    ///
    /// - Parameter config: TealiumConfig?
    func updateConsentPreferencesFromConfig(_ config: TealiumConfig?) {
        if let config = config {
            let status = config.getInitialUserConsentStatus(),
                    categories = config.getInitialUserConsentCategories()
            if let stat = status, let cat = categories {
                setUserConsentStatusWithCategories(status: stat, categories: cat)
            } else if let stat = status {
                setUserConsentStatus(stat)
            } else if let cat = categories {
                setUserConsentCategories(cat)
            }
        }
    }

     /// Sends a track call containing the consent settings if consent logging is enabled
     ///
     /// - Parameter preferences: TealiumConsentUserPreferences?
    func trackUserConsentPreferences(preferences: TealiumConsentUserPreferences?) {
        if let preferences = preferences, var consentData = preferences.toDictionary() {
            // we can't log a nil consent status
            if preferences.consentStatus == nil {
                return
            }

            let policy = tealiumConfig?.getOverrideConsentPolicy() ?? TealiumConsentConstants.defaultPolicy
            consentData[TealiumConsentConstants.policyKey] = policy

            let totalCategories = TealiumConsentCategories.all().count
            if preferences.consentStatus == .consented {
                if let currentCategories = preferences.consentCategories?.count, currentCategories < totalCategories {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentPartialEventName
                } else {
                    consentData[TealiumKey.event] = TealiumConsentConstants.consentGrantedEventName
                }
            } else {
                consentData[TealiumKey.event] = TealiumConsentConstants.consentDeclinedEventName
            }

            // this track call must only be sent if "Log Consent Changes" is enabled and user has consented
            if consentLoggingEnabled {
                // call type must be set to override "link" or "view"
                consentData[TealiumKey.callType] = consentData[TealiumKey.event]
                moduleDelegate?.tealiumModuleRequests(module: nil, process: TealiumTrackRequest(data: consentData, completion: nil))
            }
            // in all cases, update the cookie data in TiQ/webview
            updateTIQCookie(consentData)
        }
    }

    /// Sends the track call to update TiQ cookie info. Ignored by Collect module.
    ///
    /// - Parameter consentData: [String: Any] containing the consent preferences
    func updateTIQCookie(_ consentData: [String: Any]) {
        var consentData = consentData
        // may change: currently, a separate call is required to TiQ to set the relevant cookies in the webview
        // collect module ignores this hit
        consentData[TealiumKey.event] = TealiumKey.updateConsentCookieEventName
        consentData[TealiumKey.callType] = TealiumKey.updateConsentCookieEventName
        moduleDelegate?.tealiumModuleRequests(module: nil, process: TealiumTrackRequest(data: consentData, completion: nil))
    }

    /// - Returns: Existing preferences from UserDefaults if they exist
    func getSavedPreferences() -> TealiumConsentUserPreferences? {
        if let existingPrefs = consentPreferencesStorage.retrieveConsentPreferences() {
            var newPrefs = TealiumConsentUserPreferences(consentStatus: nil, consentCategories: nil)
            newPrefs.initWithDictionary(preferencesDictionary: existingPrefs)
            return newPrefs
        }
        return nil
    }

    /// Saves current consent preferences to UserDefaults
    func storeConsentUserPreferences() {
        guard let consentUserPrefs = getUserConsentPreferences()?.toDictionary() else {
            return
        }
        // store data
        consentPreferencesStorage.storeConsentPreferences(consentUserPrefs)
    }

    /// Sets the current consent preferences
    ///
    /// - Parameter prefs: TealiumConsentUserPreferences
    func setConsentUserPreferences(_ prefs: TealiumConsentUserPreferences) {
        consentUserPreferences = prefs
    }

    /// - Returns: TealiumConsentTrackAction indicating whether tracking is allowed or forbidden
    /// Used by the Consent Manager module to determine if tracking calls can be sent
    public func getTrackingStatus() -> TealiumConsentTrackAction {
        if getUserConsentPreferences()?.consentStatus == .consented {
            return .trackingAllowed
        } else if getUserConsentPreferences()?.consentStatus == .notConsented {
            return .trackingForbidden
        }
        return .trackingQueued
    }
}

// MARK: Invoke delegate methods
extension TealiumConsentManager {

    /// Called when the consent manager will drop a request (user not consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willDropTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willDropTrackingCall(track)
        }
    }

    /// Called when the consent manager will queue a request (user consent state not determined)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willQueueTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willQueueTrackingCall(track)
        }
    }

    /// Called when the consent manager will send a request (user has consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willSendTrackingCall(_ track: TealiumTrackRequest) {
        consentDelegates.invoke {
            $0.willSendTrackingCall(track)
        }
    }

    /// Called when the user has changed their consent status
    ///
    /// - Parameter status: TealiumConsentStatus
    func consentStatusChanged(_ status: TealiumConsentStatus?) {
        guard let currentStat = status else {
            return
        }
        if currentStat == .consented {
            userConsentedToTracking()
        }
        if currentStat == .notConsented {
            userOptedOutOfTracking()
        }
        consentDelegates.invoke {
            $0.consentStatusChanged(currentStat)
        }
    }

    /// Called when the user declined tracking consent
    func userOptedOutOfTracking() {
        consentDelegates.invoke {
            $0.userOptedOutOfTracking()
        }
    }

    /// Called when the user changed their consent category choices
    ///
    /// - Parameter categories: [TealiumConsentCategories] containing the new list of consent categories selected by the user
    func userChangedConsentCategories(_ categories: [TealiumConsentCategories]) {
        consentDelegates.invoke {
            $0.userChangedConsentCategories(categories: categories)
        }
    }

    /// Called when the user consented to tracking
    func userConsentedToTracking() {
        consentDelegates.invoke {
            $0.userConsentedToTracking()
        }
    }
}

// MARK: Public API
public extension TealiumConsentManager {

    /// Adds a new class conforming to TealiumConsentManagerDelegate
    ///
    /// - Parameter delegate: Class conforming to `TealiumConsentManagerDelegate` to be added
    func addConsentDelegate(_ delegate: TealiumConsentManagerDelegate) {
        if let delegate = delegate as? TealiumConsentManagerModule {
            consentManagerModuleInstance = delegate
        }
        consentDelegates.add(delegate)
    }

    /// Removes all consent delegates except the consent manager module itself
    func removeAllConsentDelegates() {
        consentDelegates.removeAll()
        // ensures that consent manager module is always maintained as a delegate if removeAll is invoked
        if let consentModule = consentManagerModuleInstance {
            consentDelegates.add(consentModule)
        }
    }

    /// Removes a specific consent delegate
    ///
    /// - Parameter delegate: Class conforming to `TealiumConsentManagerDelegate` to be removed
    func removeSingleDelegate(delegate: TealiumConsentManagerDelegate) {
        consentDelegates.remove(delegate)
    }

    /// Sets consent status only. Will set the full list of consent categories if the status is `.consented`.
    ///
    /// - Parameter status: TealiumConsentStatus?
    func setUserConsentStatus(_ status: TealiumConsentStatus) {
        var categories = [TealiumConsentCategories]()
        if status == .consented {
            categories = TealiumConsentCategories.all()
        }
        setUserConsentStatusWithCategories(status: status, categories: categories)
    }

    func setUserConsentCategories(_ categories: [TealiumConsentCategories]) {
        setUserConsentStatusWithCategories(status: .consented, categories: categories)
    }

    /// Can set both Consent Status and Consent Categories in a single call
    ///
    /// - Parameters:
    /// - status: TealiumConsentStatus?
    /// - categories: [TealiumConsentCategories]?
    func setUserConsentStatusWithCategories(status: TealiumConsentStatus?, categories: [TealiumConsentCategories]?) {
        // delegate method
        if let categories = categories, let previousCategories = consentUserPreferences?.consentCategories, !consentCategoriesEqual(categories, previousCategories) {
            userChangedConsentCategories(categories)
        }
        guard let _ = consentUserPreferences else {
            consentUserPreferences = TealiumConsentUserPreferences(consentStatus: status, consentCategories: categories)
            trackUserConsentPreferences(preferences: consentUserPreferences)
            storeConsentUserPreferences()
            return
        }

        if let status = status {
            consentUserPreferences?.setConsentStatus(status)
        }
        if let categories = categories {
            consentUserPreferences?.setConsentCategories(categories)
        }
        storeConsentUserPreferences()
        trackUserConsentPreferences(preferences: consentUserPreferences)
        consentStatusChanged(status)
    }

    /// Utility method to determine if consent categories have changed
    ///
    /// - Parameters:
    /// - lhs: [TealiumConsentCategories]
    /// - rhs: [TealiumConsentCategories]
    func consentCategoriesEqual(_ lhs: [TealiumConsentCategories], _ rhs: [TealiumConsentCategories]) -> Bool {
        let lhs = lhs.sorted { $0.rawValue < $1.rawValue }
        let rhs = rhs.sorted { $0.rawValue < $1.rawValue }
        return lhs == rhs
    }

    /// - Returns: TealiumConsentStatus
    func getUserConsentStatus() -> TealiumConsentStatus {
        return consentUserPreferences?.consentStatus ?? TealiumConsentStatus.unknown
    }

    /// - Returns: [TealiumConsentCategories]? containing all current consent categories
    func getUserConsentCategories() -> [TealiumConsentCategories]? {
        return consentUserPreferences?.consentCategories
    }

    /// - Returns: TealiumConsentUserPreferences? containing all current consent preferences
    func getUserConsentPreferences() -> TealiumConsentUserPreferences? {
        return consentUserPreferences
    }

    /// Resets all consent preferences in memory and in persistent storage
    func resetUserConsentPreferences() {
        consentPreferencesStorage.clearStoredPreferences()
        consentUserPreferences?.resetConsentCategories()
        consentUserPreferences?.setConsentStatus(.unknown)
        consentStatusChanged(consentUserPreferences?.consentStatus)
        userChangedConsentCategories([TealiumConsentCategories]())
        trackUserConsentPreferences(preferences: consentUserPreferences)
    }
}
