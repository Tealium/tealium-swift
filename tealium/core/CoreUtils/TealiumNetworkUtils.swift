//
//  TealiumNetworkUtils.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/02/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

/// Returns a JSON string from a dictionary input.
///
/// - Parameter dictionary: `[String: Any]`
/// - Returns: `String?`
public func jsonString(from dictionary: [String: Any]) -> String? {
    return TealiumQueues.backgroundConcurrentQueue.read { () -> String? in
        var writingOptions: JSONEncoder.OutputFormatting

        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *) {
            writingOptions = [.prettyPrinted, .sortedKeys]
        } else {
            writingOptions = [.prettyPrinted]
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = writingOptions
        let encodable = dictionary.encodable
        if let jsonData = try? encoder.encode(encodable) {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }
}
/// Returns a JSON string from an array of dictionaries.
///
/// - Parameter array: `[[String: Any]]`
/// - Returns: `String?`
public func jsonString(from array: [[String: Any]]) -> String? {
    return TealiumQueues.backgroundConcurrentQueue.read { () -> String? in
        var writingOptions: JSONEncoder.OutputFormatting

        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *) {
            writingOptions = [.prettyPrinted, .sortedKeys]
        } else {
            writingOptions = [.prettyPrinted]
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = writingOptions
        let encodable = AnyEncodable(array)
        if let jsonData = try? encoder.encode(encodable) {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }
}

/// Prepares a URLRequest for a given JSON string and endpoint.
///
/// - Parameters:
///     - jsonString: `String`
///     - dispatchURL: `String` containing a URL for the URLRequest
public func urlPOSTRequestWithJSONString(_ jsonString: String,
                                         dispatchURL: String) -> URLRequest? {
   return TealiumQueues.backgroundConcurrentQueue.read { () -> URLRequest? in
        if let dispatchURL = URL(string: dispatchURL) {
            var request = URLRequest(url: dispatchURL)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            if let data = try? jsonString.data(using: .utf8)?.gzipped(level: .bestCompression) {
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

public extension Dictionary {
    func toJSONString() -> String? {
        var writingOptions: JSONSerialization.WritingOptions
        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, OSX 10.13, *) {
            writingOptions = [.prettyPrinted, .sortedKeys]
        } else {
            writingOptions = [.prettyPrinted]
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: writingOptions) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
}
