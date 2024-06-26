//
//  DataLayerExtensions.swift
//  TealiumSwift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    /// Defines lookup keys for the Hosted Data Layer.
    /// The dictionary `key` denotes the event name (`tealium_event`) for which the lookup should be performed, e.g. `"product_view"`
    /// The dictionary `value` denotes the name of the data layer key that should looked up for this event, e.g. `"product_id".`
    var hostedDataLayerKeys: [String: String]? {
        get {
            options[TealiumConfigKey.hostedDataLayerKeys] as? [String: String]
        }

        set {
            options[TealiumConfigKey.hostedDataLayerKeys] = newValue
        }
    }

    /// Sets the expiry for the Hosted Data Layer cache.
    var hostedDataLayerExpiry: (Int, unit: TimeUnit) {
        get {
            options[TealiumConfigKey.hostedDataLayerExpiry] as? (Int, unit: TimeUnit) ?? TealiumValue.defaultHDLExpiry
        }

        set {
            options[TealiumConfigKey.hostedDataLayerExpiry] = newValue
        }
    }
}

public extension TealiumValue {
    static let defaultMinutesBetweenSession = 30
    static let defaultsSecondsBetweenTrackEvents = 30.0
    static let sessionBaseURL = "\(TealiumValue.tiqBaseURL)tiqapp/utag.v.js?a="
}

public extension TealiumDataKey {
    static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestamp = "timestamp"
    static let timestampLocal = "timestamp_local"
    static let timestampOffset = "timestamp_offset"
}

extension Date {
    var timestampInSeconds: String {
        let timestamp = self.timeIntervalSince1970
        return "\(Int(timestamp))"
    }
    var timestampInMilliseconds: String {
        let timestamp = self.unixTimeMilliseconds
        return timestamp
    }
}

public extension String {
    var dateFromISOString: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: self)
    }
    var dateFromISOStringShort: Date? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        return dateFormatter.date(from: self)
    }
}

public enum SessionError: LocalizedError {
    case errorInRequest
    case invalidResponse
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .errorInRequest:
            return NSLocalizedString("Error when requesting a new session: ", comment: "errorInRequest")
        case .invalidResponse:
            return NSLocalizedString("Invalid response when requesting a new session.", comment: "invalidResponse")
        case .invalidURL:
            return NSLocalizedString("The url is invalid.", comment: "invalidURL")
        }
    }

}
