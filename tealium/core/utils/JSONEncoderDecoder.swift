//
//  Tealium.jsonEncoderDecoder.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        encoder.dateEncodingStrategy = .formatted(Date.Formatter.iso8601)
        return encoder
    }()

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        decoder.dateDecodingStrategy = .formatted(Date.Formatter.iso8601)
        return decoder
    }()
}

public class JSONLoader {

    enum JSONLoaderError: String, LocalizedError {

        case invalidURL = "URL is invalid."
        case noURL = "URL is empty."
        case noJSON = "JSON is empty."
        case fileNotFound = "File does not exist."
        case couldNotDecode = "Could not decode JSON."
        case couldNotRetrieve = "Could not retrieve JSON."

        public var errorDescription: String? {
            return self.rawValue
        }
    }

    fileprivate init() {}

    public static func fromFile<T: Codable>(_ file: String,
                                            bundle: Bundle,
                                            logger: TealiumLoggerProtocol? = nil) throws -> T {

        guard let path = bundle.path(forResource: file.replacingOccurrences(of: ".json", with: ""),
                                     ofType: "json") else {
            throw JSONLoaderError.fileNotFound
        }
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            throw JSONLoaderError.couldNotRetrieve
        }
        guard let converted = try? Tealium.jsonDecoder.decode(T.self, from: jsonData) else {
            throw JSONLoaderError.couldNotDecode
        }
        return converted
    }

    public static func fromURL<T: Codable>(url: String,
                                           logger: TealiumLoggerProtocol? = nil) throws -> T {
        guard !url.isEmpty else {
            throw JSONLoaderError.noURL
        }
        guard let geofenceUrl = URL(string: url) else {
            throw JSONLoaderError.invalidURL
        }
        guard let jsonString = try? String(contentsOf: geofenceUrl) else {
            throw JSONLoaderError.couldNotRetrieve
        }
        guard let data = jsonString.data(using: .utf8),
              let converted = try? Tealium.jsonDecoder.decode(T.self, from: data) else {
            throw JSONLoaderError.couldNotDecode
        }
        return converted
    }

    public static func fromString<T: Codable>(json: String,
                                              logger: TealiumLoggerProtocol? = nil) throws -> T {
        guard !json.isEmpty else {
            throw JSONLoaderError.noJSON
        }
        guard let data = json.data(using: .utf8),
              let converted = try? Tealium.jsonDecoder.decode(T.self, from: data) else {
            throw JSONLoaderError.couldNotDecode
        }
        return converted
    }

}
