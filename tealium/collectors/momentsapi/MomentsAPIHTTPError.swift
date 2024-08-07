import Foundation

enum MomentsAPIHTTPError: RawRepresentable, Error, LocalizedError, Equatable {
    typealias RawValue = Int

    case badRequest
    case forbidden
    case notFound
    case unsuccessful(_ statusCode: Int)

    init?(rawValue: Int) {
        switch rawValue {
        case 200..<300:
            return nil
        case 400:
            self = .badRequest
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        default:
            self = .unsuccessful(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .badRequest:
            return 400
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .unsuccessful(let code):
            return code
        }
    }

    var errorDescription: String? {
        switch self {
        case .badRequest:
            return "Bad request. Please check the request parameters."
        case .forbidden:
            return "The Moments API engine is not enabled. Please check your configuration."
        case .notFound:
            return "Not Found. The Tealium visitor ID does not have moments stored in the database."
        case .unsuccessful(let statusCode):
            return "An error occurred with status code \(statusCode)."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .badRequest:
            return "Verify the request parameters and try again."
        case .forbidden:
            return "Ensure that the Moments API engine is properly configured and enabled."
        case .notFound:
            return "Check the Tealium visitor ID."
        case .unsuccessful:
            return "Please consult the documentation or contact support for further assistance."
        }
    }

    static func == (lhs: MomentsAPIHTTPError, rhs: MomentsAPIHTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.badRequest, .badRequest),
             (.forbidden, .forbidden),
             (.notFound, .notFound):
            return true
        case let (.unsuccessful(lhsCode), .unsuccessful(rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}
