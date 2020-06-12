//
//  MockDiskStorage.swift
//  TealiumVisitorProfileTests
//
//  Created by Christina Sund on 8/22/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

public class MockTealiumDiskStorage: TealiumDiskStorageProtocol {
    public func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    public func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    public var saveCount = 0
    public var retrieveCount = 0

    public func save(_ data: AnyCodable, completion: TealiumCompletion?) {
        saveCount += 1
    }

    public func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {
        saveCount += 1
    }

    public func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
        saveCount += 1
    }

    public func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {
        saveCount += 1
    }

    public func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    public func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    public func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        retrieveCount += 1
        return nil
    }

    public func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        retrieveCount += 1
        return nil
    }

   public func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) {
        retrieveCount += 1
    }

    public func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) {
    }

    public func delete(completion: TealiumCompletion?) {
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
