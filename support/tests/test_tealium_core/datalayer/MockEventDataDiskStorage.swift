//
//  MockDataLayerDiskStorage.swift
//  TealiumCoreTests
//
//  Created by Christina S on 4/28/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

class MockDataLayerDiskStorage: TealiumDiskStorageProtocol {

    var mockEventData: DataLayerCollection?

    init() {
        let dataItem1 = DataLayerItem(key: "singleDataItemKey1", value: "singleDataItemValue1", expires: .distantFuture)
        let dataItem2 = DataLayerItem(key: "singleDataItemKey2", value: "singleDataItemValue2", expires: .distantFuture)
        mockEventData = DataLayerCollection(arrayLiteral: dataItem1, dataItem2)
    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == DataLayerCollection.self,
            let data = data as? DataLayerCollection else {
                return
        }
        mockEventData = data
        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == DataLayerCollection.self else {
            return nil
        }
        if let mockEventData = self.mockEventData {
            return mockEventData as? T
        } else {
            return nil
        }
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
