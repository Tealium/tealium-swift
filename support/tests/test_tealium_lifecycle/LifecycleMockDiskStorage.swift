//
//  AttributionMockDiskStorage.swift
//  tealium-swift
//
//  Created by Craig Rouse on 30/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumLifecycle

class LifecycleMockDiskStorage: TealiumDiskStorageProtocol {

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == Lifecycle.self
        else {
            return nil
        }
        if let lifecycleData = self.lifecycleData {
            return lifecycleData as? T
        } else {
            return nil
        }
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    var lifecycleData: Lifecycle! = Lifecycle()

    func save(_ data: AnyCodable, completion: TealiumCompletion?) {

    }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {
    }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        guard T.self == Lifecycle.self,
              let data = data as? Lifecycle else {
            return
        }
        self.lifecycleData = data
        completion?(true, nil, nil)
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {
    }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    //    func retrieve<T>(as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
    //        guard T.self == TealiumLifecycle.self,
    //            let completion = completion as? (Bool, TealiumLifecycle?, Error?) -> Void
    //            else {
    //                return
    //        }
    //        if let lifecycleData = self.lifecycleData {
    //            completion(true, lifecycleData, nil)
    //        } else {
    //            completion(false, nil, nil)
    //        }
    //    }

    //    func retrieve<T>(_ fileName: String, as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
    //    }

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
