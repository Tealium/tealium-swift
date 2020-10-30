//
//  AttributionMockDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumAttribution
@testable import TealiumCore

class AttributionMockDiskStorage: TealiumDiskStorageProtocol {

    var retrieveCount = 0

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) {

    }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {

    }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {

    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {
    }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func retrieve<T>(as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
        guard T.self == PersistentAttributionData.self,
              let completion = completion as? (Bool, PersistentAttributionData?, Error?) -> Void
        else {
            return
        }
        let mockData: [String: String] = Dictionary(uniqueKeysWithValues: AttributionKey.allCases.map { ($0, "mockdata") })
        retrieveCount += 1
        completion(true, PersistentAttributionData(withDictionary: mockData), nil)
    }

    func retrieve<T>(_ fileName: String, as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
    }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == PersistentAttributionData.self else {
            return nil
        }
        let mockData: [String: String] = Dictionary(uniqueKeysWithValues: AttributionKey.allCases.map { ($0, "mockdata") })
        retrieveCount += 1
        return PersistentAttributionData(withDictionary: mockData) as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) {

    }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) {

    }

    func delete(completion: TealiumCompletion?) {
        completion?(true, nil, nil)
    }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) {

    }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) {

    }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) {

    }

    func canWrite() -> Bool {
        return true
    }
}
