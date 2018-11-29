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
