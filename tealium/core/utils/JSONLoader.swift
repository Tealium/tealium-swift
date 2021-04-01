//
//  JSONLoader.swift
//  TealiumCore
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol JSONLoadable: AnyObject {
        
    func fromFile<T: Codable>(_ file: String,
                  bundle: Bundle,
                  logger: TealiumLoggerProtocol?) throws -> T?
    
    func fromURL<T: Codable>(url: String,
                 logger: TealiumLoggerProtocol?) throws -> T?
    
    func fromString<T: Codable>(json: String,
                    logger: TealiumLoggerProtocol?) throws -> T?
}

public class JSONLoader: JSONLoadable {
    
    enum JSONLoaderError: String, LocalizedError {
        case invalidURL
        case noURL
        case noJSON
        case fileNotFound
        case couldNotDecode
        case couldNotRetrieve
        
        public var errorDescription: String? {
            return self.rawValue
        }
    }
    
    public init() { }
    
    public func fromFile<T: Codable>(_ file: String,
                         bundle: Bundle,
                         logger: TealiumLoggerProtocol? = nil) throws -> T? {
        
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
    
    public func fromURL<T: Codable>(url: String,
                                           logger: TealiumLoggerProtocol? = nil) throws -> T? {
        guard !url.isEmpty else {
            throw JSONLoaderError.noURL
        }
        guard let url = URL(string: url) else {
            throw JSONLoaderError.invalidURL
        }
        do {
            let jsonString = try String(contentsOf: url)
            guard let data = jsonString.data(using: .utf8),
                  let converted = try? Tealium.jsonDecoder.decode(T.self, from: data) else {
                return nil
            }
            return converted
        } catch let error {
            throw error
        }
    }
    
    public func fromString<T: Codable>(json: String,
                                       logger: TealiumLoggerProtocol? = nil) throws -> T? {
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
