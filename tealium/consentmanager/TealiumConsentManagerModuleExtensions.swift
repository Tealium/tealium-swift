//
//  TealiumConsentManagerModuleExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

extension TealiumConsentManagerModule: TealiumConsentManagerDelegate {

    /// Called when the consent manager will drop a request (user not consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willDropTrackingCall(_ request: TealiumTrackRequest) {

    }

    /// Called when the consent manager will queue a request (user consent state not determined)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willQueueTrackingCall(_ request: TealiumTrackRequest) {

    }

    /// Called when the consent manager will send a request (user has consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willSendTrackingCall(_ request: TealiumTrackRequest) {

    }

    /// Called when the user has changed their consent status
    ///
    /// - Parameter status: TealiumConsentStatus
    func consentStatusChanged(_ status: TealiumConsentStatus) {
        switch status {
        case .notConsented:
            purgeQueue()
        case .consented:
            releaseQueue()
        default:
            return
        }
    }

    /// Called when the user consented to tracking
    func userConsentedToTracking() {

    }

    /// Called when the user declined tracking consent
    func userOptedOutOfTracking() {

    }

    /// Called when the user changed their consent category choices
    ///
    /// - Parameter categories: [TealiumConsentCategories] containing the new list of consent categories selected by the user
    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {

    }
}

// public interface for consent manager
public extension Tealium {

    /// - Returns: TealiumConsentManager instance
    func consentManager() -> TealiumConsentManager? {
        guard let module = modulesManager.getModule(forName: TealiumConsentConstants.moduleName) as? TealiumConsentManagerModule else {
            return nil
        }

        return module.consentManager
    }
}
