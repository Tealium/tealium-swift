//
//  TealiumDispatchQueueConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/27/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

enum TealiumDispatchQueueConstants {
    static let defaultMaxQueueSize = 40
    static let moduleName = "dispatchqueue"
    // max stored events (e.g. if offline) to limit disk space consumed
    static let queueSizeKey = "queue_size"
    // number of events in a batch, max 10
    static let batchSizeKey = "batch_size"
    // dispatchEventLimit
    static let eventLimit = "event_limit"
    static let batchingEnabled = "batching_enabled"
    static let batchingBypassKeys = "batching_bypass_keys"
    static let defaultBatchExpirationDays = 7
    static let batchExpirationDaysKey = "batch_expiration_days"
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
