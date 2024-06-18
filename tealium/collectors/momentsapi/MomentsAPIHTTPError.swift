//
//  MomentsAPIHTTPError.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

enum MomentsAPIHTTPError: Int, Error, LocalizedError {
    case success = 200
    case badRequest = 400
    case forbidden = 403
    case notFound = 404

    var errorDescription: String? {
        switch self {
        case .success:
            return "The request succeeded."
        case .badRequest:
            return "Bad request. Please check the request parameters."
        case .forbidden:
            return "The Moments API engine is not enabled. Please check your configuration."
        case .notFound:
            return "Not Found. The Tealium visitor ID does not have moments stored in the database."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .success:
            return nil
        case .badRequest:
            return "Verify the request parameters and try again."
        case .forbidden:
            return "Ensure that the Moments API engine is properly configured and enabled."
        case .notFound:
            return "Check the Tealium visitor ID."
        }
    }
}
