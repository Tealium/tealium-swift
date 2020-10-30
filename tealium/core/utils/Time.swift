//
//  Time.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public enum RefreshTime {
    case seconds
    case minutes
    case hours
}

public enum TealiumRefreshInterval {
    case every(Int, RefreshTime)

    /// Converts unit and amount of time to seconds
    public var interval: TimeInterval {
        switch self {
        // swiftlint:disable pattern_matching_keywords
        case .every(let value, let unit):
            return TimeInterval(value * transform(unit))
        }
        // swiftlint:enable pattern_matching_keywords
    }

    /// Transforms unit to seconds multiplier
    private func transform(_ unit: RefreshTime) -> Int {
        switch unit {
        case .seconds:
            return 1
        case .minutes:
            return 60
        case .hours:
            return 3600
        }
    }

}
