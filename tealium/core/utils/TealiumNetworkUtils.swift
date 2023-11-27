//
//  TealiumNetworkUtils.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Dictionary where Key == String, Value == Any {
    func toJSONString() throws -> String? {
        let writingOptions: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys]

        let encoder = Tealium.jsonEncoder
        encoder.outputFormatting = writingOptions
        let encodable = self.encodable
        let jsonData = try encoder.encode(encodable)
        return String(data: jsonData, encoding: .utf8)
    }
}

public class NetworkUtils {
    /// Prepares a URLRequest for a given JSON string and endpoint.
    ///
    /// - Parameters:
    ///     - jsonString: `String`
    ///     - dispatchURL: `String` containing a URL for the URLRequest
    public static func urlPOSTRequestWithJSONString(_ jsonString: String,
                                                    dispatchURL: String) -> URLRequest? {
        if let dispatchURL = URL(string: dispatchURL) {
            var request = URLRequest(url: dispatchURL)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            if let data = ((try? jsonString.data(using: .utf8)?.gzipped(level: .bestCompression)) as Data??) {
                request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
                request.httpBody = data
            } else {
                request.httpBody = jsonString.data(using: .utf8)
            }
            return request
        }
        return nil
    }
}

public enum NetworkError: String, LocalizedError {
    case couldNotCreateSession
    case unknownResponseType
    case noInternet
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
    case invalidURL

    public var errorDescription: String? {
        return self.rawValue
    }
}
