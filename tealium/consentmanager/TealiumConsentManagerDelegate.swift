//
//  TealiumConsentManagerDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/19/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

public protocol TealiumConsentManagerDelegate: class {

    /// Called when the consent manager will drop a request (user not consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willDropTrackingCall(_ request: TealiumTrackRequest)

    /// Called when the consent manager will queue a request (user consent state not determined)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willQueueTrackingCall(_ request: TealiumTrackRequest)

    /// Called when the consent manager will send a request (user has consented)
    ///
    /// - Parameter request: TealiumTrackRequest
    func willSendTrackingCall(_ request: TealiumTrackRequest)

    /// Called when the user has changed their consent status
    ///
    /// - Parameter status: TealiumConsentStatus
    func consentStatusChanged(_ status: TealiumConsentStatus)

    /// Called when the user consented to tracking
    func userConsentedToTracking()

    /// Called when the user declined tracking consent
    func userOptedOutOfTracking()

    /// Called when the user changed their consent category choices
    ///
    /// - Parameter categories: [TealiumConsentCategories] containing the new list of consent categories selected by the user
    func userChangedConsentCategories(categories: [TealiumConsentCategories])
    // future implementation
    // func consentSettingsReady(settings: [String: String])
}
