//
//  MockHDLDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

import Foundation
@testable import TealiumCore

class MockHDLDiskStorageFullCache: TealiumDiskStorageProtocol {

    var mockCache = [HostedDataLayerCacheItem]()

    init() {
        for _ in 0...50 {
            mockCache.append(HostedDataLayerCacheItem(id: "\(Int.random(in: 0...10_000))", data: ["product_name": "test"]))
        }
    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == [HostedDataLayerCacheItem].self,
              let data = data as? [HostedDataLayerCacheItem] else {
            return
        }

        self.mockCache = data

        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == [HostedDataLayerCacheItem].self else {
            return nil
        }
        return self.mockCache as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}

class MockHDLDiskStorageEmptyCache: TealiumDiskStorageProtocol {

    var mockCache = [HostedDataLayerCacheItem]()

    init() {

    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == [HostedDataLayerCacheItem].self,
              let data = data as? [HostedDataLayerCacheItem] else {
            return
        }

        self.mockCache = data

        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == [HostedDataLayerCacheItem].self else {
            return nil
        }
        return self.mockCache as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}

class MockHDLDiskStorageExpiringCache: TealiumDiskStorageProtocol {

    var mockCache = [HostedDataLayerCacheItem]()

    var referenceDate = Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 0, minute: 0, second: 0))

    init() {
        mockCache = [
            HostedDataLayerCacheItem(id: "abc123", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 1, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "bcd234", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 1, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "cde345", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 1, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "def456", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2019, month: 1, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "efg567", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2020, month: 2, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "fgh678", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2020, month: 2, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "ghi789", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2020, month: 2, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "hij890", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2020, month: 2, day: 1, hour: 0, minute: 0, second: 0))!),
            HostedDataLayerCacheItem(id: "ijk901", data: ["product_color": "blue"], retrievalDate: Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2050, month: 2, day: 1, hour: 0, minute: 0, second: 0))!),
        ]
    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == [HostedDataLayerCacheItem].self,
              let data = data as? [HostedDataLayerCacheItem] else {
            return
        }

        self.mockCache = data

        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == [HostedDataLayerCacheItem].self else {
            return nil
        }
        return self.mockCache as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}
