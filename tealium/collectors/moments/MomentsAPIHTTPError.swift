import Foundation

enum MomentsAPIHTTPError: Error, LocalizedError, Equatable {
    case success
    case badRequest
    case forbidden
    case notFound
    case unknown(statusCode: Int)

    init(statusCode: Int) {
        switch statusCode {
        case 200:
            self = .success
        case 400:
            self = .badRequest
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        default:
            self = .unknown(statusCode: statusCode)
        }
    }

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
        case .unknown(let statusCode):
            return "An unknown error occurred with status code \(statusCode)."
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
        case .unknown:
            return "Please consult the documentation or contact support for further assistance."
        }
    }
}
