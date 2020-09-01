//
//  TealiumDiskStorageProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 21/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumDiskStorageProtocol {
    func save(_ data: AnyCodable,
              completion: TealiumCompletion?)

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk.
    ///
    /// - Parameters:
    ///     - data: `AnyCodable` to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    func save(_ data: AnyCodable,
              fileName: String,
              completion: TealiumCompletion?)

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk
    ///
    /// - Parameters:
    ///     - data: `AnyCodable` to be saved
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    func save<T: Encodable>(_ data: T,
                            completion: TealiumCompletion?)

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk
    ///
    /// - Parameters:
    ///     - data: `T` Encodable object to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    func save<T: Encodable>(_ data: T,
                            fileName: String,
                            completion: TealiumCompletion?)

    /// Appends data to existing data of the same type.
    ///
    /// - Parameters:
    ///     - data: `Codable` object to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    func append<T: Codable>(_ data: T,
                            completion: TealiumCompletion?)

    /// Appends data to existing data of the same type.
    ///
    /// - Parameters:
    ///     - data: `Codable` object to be saved
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    func append<T: Codable>(_ data: T,
                            fileName: String,
                            completion: TealiumCompletion?)

    /// Appends data to a `[String: Any]`.
    ///
    /// - Parameters:
    ///     - data: `[String: Any]` to be appended
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    func append(_ data: [String: Any],
                fileName: String,
                completion: TealiumCompletion?)

    /// Retrieves a `Decodable` item from disk storage.
    ///
    /// - Parameters:
    ///     - type: `T.Type` type of data to be retrieved
    ///     - completion: completion to be called upon retrieval
    func retrieve<T: Decodable>(as type: T.Type) -> T?

    /// Retrieves a `Decodable` item from disk storage.
    ///
    /// - Parameters:
    ///     - type: `T.Type` type of data to be retrieved
    ///     - fileName: `String` containing the filename for the data to be retrieved
    ///     - completion: completion to be called upon retrieval
    func retrieve<T: Decodable>(_ fileName: String,
                                as type: T.Type) -> T?

    /// Retrieves a `[String: Any]` from disk storage.
    ///
    /// - Parameters:
    ///     - fileName: `String` containing the filename for the data to be retrieved
    ///     - completion: completion to be called upon retrieval
    func retrieve(fileName: String,
                  completion: TealiumCompletion)

    /// Updates a value for any `Codable` object representable as a `[String: Any]`.
    ///
    /// - Parameters:
    ///     - value: `Any` value to be set on the `Codable` object
    ///     - key: `String` representing the key to be updated on the codable object
    ///     - type: `T.Type` concrete type of the object to be updated
    ///     - completion: Optional compeletion block to be run after update
    func update<T: Codable>(value: Any,
                            for key: String,
                            as type: T.Type,
                            completion: TealiumCompletion?)

    /// Deletes all data for the current module.
    ///
    /// - Parameter completion: Completion block to be called upon deletion
    func delete(completion: TealiumCompletion?)

    /// Gets the total size of all data saved by this module.
    ///
    /// - Returns: `String` containing the total size in bytes of data saved by this module
    func totalSizeSavedData() -> String?

    /// Saves a `String` value to UserDefaults.
    ///
    /// - Parameters:
    ///     - key: `String`
    ///     - value: `String`
    func saveStringToDefaults(key: String,
                              value: String)

    /// Retrieves a `String` value from UserDefaults.
    ///
    /// - Parameter key: `String`
    /// - Returns: `String?`
    func getStringFromDefaults(key: String) -> String?

    /// Saves `Any` value to UserDefaults.
    ///
    /// - Parameters:
    ///     - key: `String`
    ///     - value: `Any`
    func saveToDefaults(key: String,
                        value: Any)

    /// Retrieves `Any` value from UserDefaults
    ///
    /// - Parameter key: `String`
    /// - Returns: `Any?`
    func getFromDefaults(key: String) -> Any?

    /// Deletes a value from UserDefaults
    ///
    /// - Parameter key: `String`
    func removeFromDefaults(key: String)

    /// - Returns: `Bool` `true` if there is sufficient disk space
    func canWrite() -> Bool

}
