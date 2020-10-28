//
//  DataLayerExtensions.swift
//  TealiumSwift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {

    /// - Returns: `String` The Tealium Visitor Id
    var visitorId: String? {
        zz_internal_modulesManager?.collectors.first {
            $0 is AppDataModule
        }?.data?[TealiumKey.visitorId] as? String
    }

}

public extension TealiumConfig {

    var hostedDataLayerKeys: [String: String]? {
        get {
            options[TealiumKey.hostedDataLayerKeys] as? [String: String]
        }

        set {
            options[TealiumKey.hostedDataLayerKeys] = newValue
        }
    }

    var hostedDataLayerExpiry: (Int, unit: TimeUnit) {
        get {
            options[TealiumKey.hostedDataLayerExpiry] as? (Int, unit: TimeUnit) ?? TealiumValue.defaultHDLExpiry
        }

        set {
            options[TealiumKey.hostedDataLayerExpiry] = newValue
        }
    }
}

public extension TealiumValue {
    static let defaultMinutesBetweenSession = 30
    static let defaultsSecondsBetweenTrackEvents = 30.0
    static let sessionBaseURL = "https://tags.tiqcdn.com/utag/tiqapp/utag.v.js?a="
}

public extension TealiumKey {
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
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
            return dateFormatter.date(from: self)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.autoupdatingCurrent
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return dateFormatter.date(from: self)
        }
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
