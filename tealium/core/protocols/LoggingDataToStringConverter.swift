//
//  LoggingDataToStringConverter.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 08/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

extension Error {
    func toLogRequest(_ message: String? = nil) -> TealiumLogRequest {
        TealiumLogRequest(title: self.localizedDescription, message: message ?? String(describing: self), info: nil, logLevel: .error, category: .track)
    }
}

extension EncodingError {
    func toEncodingErrorLogRequest() -> TealiumLogRequest {
        switch self {
        case .invalidValue(_, let context):
            return toLogRequest(context.debugDescription)
        @unknown default:
            return toLogRequest()
        }
    }
}

public protocol LoggingDataToStringConverter {
    var logger: TealiumLoggerProtocol? { get }
}

public extension LoggingDataToStringConverter {
    func convertData(_ data: [String: Any], toStringWith conversionBlock: ([String: Any]) throws -> String?) -> String? {
        let jsonString: String?
        do {
            jsonString = try conversionBlock(data)
        } catch {
            if let logger = self.logger {
                let request: TealiumLogRequest
                if let encodingError = error as? EncodingError {
                    request = encodingError.toEncodingErrorLogRequest()
                } else {
                    request = error.toLogRequest()
                }
                logger.log(request)
            }
            jsonString = nil
        }
        return jsonString
    }
}
