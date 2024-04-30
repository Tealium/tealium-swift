//
//  MomentsAPIError.swift
//  TealiumMoments
//
//  Created by Craig Rouse on 29/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

enum MomentsError: Error, LocalizedError {
    case missingRegion
    case missingVisitorID
    
    public var errorDescription: String? {
        switch self {
        case .missingRegion:
            return "Missing Region."
        case .missingVisitorID:
            return "Missing Visitor ID."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingRegion:
            return "Set momentsAPIRegion property on TealiumConfig."
        case .missingVisitorID:
            return "Tealium Anonymous Visitor ID could not be determined. This is likely to be a temporary error, and should resolve itself."
        }
    }
}
