//
//  MockDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

public class MockTealiumDiskStorage: TealiumDiskStorageProtocol {
    var storedData: AnyCodable?
    public func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    public func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    public var saveCount = 0 {
        didSet {
            print("asd")
        }
    }
    public var retrieveCount = 0
    
    var saveToDefaultsCount = 0
    var deleteCount = 0

    public func save(_ data: AnyCodable, completion: TealiumCompletion?) {
        saveCount += 1
        storedData = data
        completion?(true, nil, nil)
    }

    public func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {
        saveCount += 1
        storedData = data
        completion?(true, nil, nil)
    }

    public func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        saveCount += 1
        storedData = AnyCodable(data)
        completion?(true, nil, nil)
    }

    public func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {
        saveCount += 1
        storedData = AnyCodable(data)
        completion?(true, nil, nil)
    }

    public func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    public func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    public func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        retrieveCount += 1
        return storedData?.value as? T
    }

    public func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        retrieveCount += 1
        return storedData?.value as? T
    }

    public func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) {
        retrieveCount += 1
        completion(true, nil, nil)
    }

    public func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) {
    }

    public func delete(completion: TealiumCompletion?) {
        completion?(true, nil, nil)
        deleteCount += 1
    }

    public func totalSizeSavedData() -> String? {
        return ""
    }

    public func saveStringToDefaults(key: String, value: String) {
    }

    public func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    public func saveToDefaults(key: String, value: Any) {
        saveToDefaultsCount += 1
    }

    public func getFromDefaults(key: String) -> Any? {
        return ""
    }

    public func removeFromDefaults(key: String) {
    }

    public func canWrite() -> Bool {
        return true
    }

}
