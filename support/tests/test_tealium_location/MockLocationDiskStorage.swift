//
//  MockLocationDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumLocation

class MockLocationDiskStorage: TealiumDiskStorageProtocol {

    var locationData: TealiumLocationManager!

    init(config: TealiumConfig) {
        locationData = TealiumLocationManager(config: config)
    }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) {

    }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {

    }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == TealiumLocationManager.self,
              let data = data as? TealiumLocationManager else {
            return
        }
        self.locationData = data
        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {

    }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == TealiumLocationManager.self else {
            return nil
        }
        if let locationData = self.locationData {
            return locationData as? T
        } else {
            return nil
        }
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) {

    }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func delete(completion: TealiumCompletion?) {

    }

    func totalSizeSavedData() -> String? {
        ""
    }

    func saveStringToDefaults(key: String, value: String) {

    }

    func getStringFromDefaults(key: String) -> String? {
        ""
    }

    func saveToDefaults(key: String, value: Any) {

    }

    func getFromDefaults(key: String) -> Any? {
        ""
    }

    func removeFromDefaults(key: String) {

    }

    func canWrite() -> Bool {
        true
    }

}
