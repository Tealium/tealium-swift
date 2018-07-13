//
//  TealiumConsentManagerDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/04/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumConsentManagerDelegate: class {

    func willDropTrackingCall(_ request: TealiumTrackRequest)
    func willQueueTrackingCall(_ request: TealiumTrackRequest)
    func willSendTrackingCall(_ request: TealiumTrackRequest)
    func consentStatusChanged(_ status: TealiumConsentStatus)
    func userConsentedToTracking()
    func userOptedOutOfTracking()
    func userChangedConsentCategories(categories: [TealiumConsentCategories])
    // future implementation
    // func consentSettingsReady(settings: [String: String])
}
