//
//  TealiumDispatchQueueConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/27/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumDispatchQueueConstants {
    static let moduleName = "dispatchqueue"
    static let batchingBypassKeys = "batching_bypass_keys"
    static let isRemoteAPIEnabled = "remote_api_enabled"
    static let lowBatteryThreshold = 20.0
    static let simulatorBatteryConstant = -100.0
    static let insufficientBatteryQueueReason = "insufficient_battery"
    static let bypassQueueKey = "bypass_queue"
}

// These events will not be subject to batching
enum BypassDispatchQueueKeys: String, CaseIterable {
    case lifecycleLaunch = "launch"
    case fullConsentGranted = "grant_full_consent"
    case partialConsentGranted = "grant_partial_consent"
    case consentDenied = "decline_consent"
    case updateConsentCookie = "update_consent_cookie"
    case killVisitorSession = "kill_visitor_session"
}
