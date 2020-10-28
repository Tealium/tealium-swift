//
//  MockAppDataDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class MockAppDataDiskStorage: TealiumDiskStorageProtocol {

    var saveCount = 0
    var saveToDefaultsCount = 0
    var retrieveCount = 0
    var deleteCount = 0

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) {

    }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {

    }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        saveCount += 1
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {

    }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func retrieve<T>(as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
        guard T.self == PersistentAppData.self,
              let completion = completion as? (Bool, PersistentAppData?, Error?) -> Void
        else {
            return
        }
        completion(true, PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID), nil)
    }

    func retrieve<T>(_ fileName: String, as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {

    }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == PersistentAppData.self else {
            return nil
        }
        retrieveCount += 1
        return PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID) as? T
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
        deleteCount += 1
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
        saveToDefaultsCount += 1
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
