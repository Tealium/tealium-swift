//
//  MomentsAPIError.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

enum MomentsError: Error, LocalizedError {
    case missingRegion
    case missingVisitorID
    case tealiumNotInitialized
    public var errorDescription: String? {
        switch self {
        case .missingRegion:
            return "Missing Region."
        case .missingVisitorID:
            return "Missing Visitor ID."
        case .tealiumNotInitialized:
            return "Tealium is not initialized."
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .missingRegion:
            return "Set momentsAPIRegion property on TealiumConfig."
        case .missingVisitorID:
            return "Tealium Anonymous Visitor ID could not be determined. This is likely to be a temporary error, and should resolve itself."
        case .tealiumNotInitialized:
            return "Create a Tealium instance before calling this method."
        }
    }
}
