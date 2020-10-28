//
// Created by Craig Rouse on 2019-06-14.
// Copyright (c) 2019 Tealium, Inc. All rights reserved.
//

import Foundation
// swiftlint:disable file_length
// swiftlint:disable type_body_length
public class TealiumDiskStorage: TealiumDiskStorageProtocol {

    static let readWriteQueue = ReadWrite("TealiumDiskStorage.label")
    let defaultDirectory = Disk.Directory.caches
    var currentDirectory: Disk.Directory
    let filePrefix: String
    let module: String
    let minimumDiskSpace: Int32
    var defaultsStorage: UserDefaults?
    let isCritical: Bool
    let isDiskStorageEnabled: Bool
    var logger: TealiumLoggerProtocol?
    lazy var filePath: String = {
        return "\(filePrefix)\(module)/"
    }()

    enum DiskStorageErrors: String {
        case couldNotEncode = "Could not encode data."
        case couldNotDecode = "Could not decode data."
        case insufficientStorage = "Insufficient storage space."
        case diskStorageDisabled = "Disk storage disabled. Could not save."
    }

    /// - Parameters:
    ///     - config: `TealiumConfig`
    ///     - module: `String` containing the module name
    ///     - isCritical: `Bool` `true` if critical. Has UserDefaults backing if diskstorage is explicitly disabled.
    public init(config: TealiumConfig,
                forModule module: String,
                isCritical: Bool = false) {
        self.logger = config.logger
        // The subdirectory to use for this data
        filePrefix = "\(config.account).\(config.profile)/"
        minimumDiskSpace = config.minimumFreeDiskSpace ?? TealiumValue.defaultMinimumDiskSpace
        self.module = module
        self.isCritical = isCritical
        self.isDiskStorageEnabled = config.diskStorageEnabled
        let defaultDirectory = self.defaultDirectory
        currentDirectory = config.diskStorageDirectory ?? defaultDirectory
        // Provides userdefaults backing for critical data (e.g. appdata, consentmanager)
        if isCritical {
            self.defaultsStorage = UserDefaults(suiteName: filePath)
        }
    }

    /// Generates a file path for the data to be saved.
    ///
    /// - Parameter name: `String` containing
    func filePath (_ name: String) -> String {
        return "\(filePath)\(name)"
    }

    /// Attempts to calculate the size in bytes of an encodable object.
    ///
    /// - Parameter data: `T` Encodable object
    func size<T: Encodable>(of data: T) -> Int? {
        do {
            return try Tealium.jsonEncoder.encode(data).count
        } catch {
            return nil
        }

    }

    /// - Parameter data: `T` Encodable object to write
    /// - Returns: `Bool` `true` if there is sufficient disk space for the item to be saved
    public func canWrite<T: Encodable>(data: T) -> Bool {
        guard let available = Disk.availableCapacity,
              let fileSize = size(of: data) else {
            return false
        }
        // make sure we have sufficient disk capacity (20MB)
        return available > minimumDiskSpace && fileSize < available
    }

    /// - Returns: `Bool` `true` if there is sufficient disk space
    public func canWrite() -> Bool {
        guard let available = Disk.availableCapacity else {
            return false
        }
        // make sure we have sufficient disk capacity (20MB)
        return available > minimumDiskSpace
    }

    /// Gets the total size of all data saved by this module.
    ///
    /// - Returns: `String` containing the total size in bytes of data saved by this module
    public func totalSizeSavedData() -> String? {
        if let fileUrl = try? Disk.url(for: filePrefix, in: currentDirectory),
           let contents = try? FileManager.default.contentsOfDirectory(at: fileUrl, includingPropertiesForKeys: nil, options: []) {

            var folderSize: Int64 = 0
            contents.forEach { file in
                let fileAttributes = try? FileManager.default.attributesOfItem(atPath: file.path)
                folderSize += fileAttributes?[FileAttributeKey.size] as? Int64 ?? 0
            }
            let fileSizeStr = ByteCountFormatter.string(fromByteCount: folderSize, countStyle: ByteCountFormatter.CountStyle.file)
            return fileSizeStr
        }
        return nil
    }

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk.
    ///
    /// - Parameters:
    ///     - data: `AnyCodable` to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    public func save(_ data: AnyCodable,
                     completion: TealiumCompletion?) {
        save(data, fileName: module, completion: completion)
    }

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk
    ///
    /// - Parameters:
    ///     - data: `AnyCodable` to be saved
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    public func save(_ data: AnyCodable,
                     fileName: String,
                     completion: TealiumCompletion?) {
        guard isDiskStorageEnabled else {
            if let data = try? Tealium.jsonEncoder.encode(data) {
                saveToDefaults(key: filePath(fileName), value: data)
                completion?(true, nil, nil)
            } else {
                log(error: DiskStorageErrors.couldNotEncode.rawValue)
                completion?(false, nil, nil)
            }
            return
        }

        TealiumDiskStorage.readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            do {
                try Disk.save(data, to: self.currentDirectory, as: self.filePath(fileName))
            } catch let error {
                completion?(false, nil, error)
            }
        }
    }

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk
    ///
    /// - Parameters:
    ///     - data: `T` Encodable object to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    public func save<T: Encodable>(_ data: T,
                                   completion: TealiumCompletion?) {
        save(data, fileName: module, completion: completion)
    }

    /// Saves new data to disk, overwriting existing data.
    /// Used when a module keeps an in-memory copy of data and needs to occasionally persist the whole object to disk
    ///
    /// - Parameters:
    ///     - data: `T` Encodable object to be saved
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the save operation
    public func save<T: Encodable>(_ data: T,
                                   fileName: String,
                                   completion: TealiumCompletion?) {
        guard isDiskStorageEnabled else {
            if let data = try? Tealium.jsonEncoder.encode(data) {
                saveToDefaults(key: filePath(fileName), value: data)
                completion?(true, nil, nil)
            } else {
                log(error: DiskStorageErrors.couldNotEncode.rawValue)
                completion?(false, nil, nil)
            }
            return
        }

        TealiumDiskStorage.readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            do {
                guard self.canWrite(data: data) == true else {
                    self.log(error: DiskStorageErrors.couldNotEncode.rawValue)
                    completion?(false, nil, nil)
                    return
                }
                try Disk.save(data, to: self.currentDirectory, as: self.filePath(fileName))
            } catch let error {
                completion?(false, nil, error)
            }
        }
    }

    /// Appends data to existing data of the same type.
    ///
    /// - Parameters:
    ///     - data: `Codable` object to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    public func append<T: Codable>(_ data: T,
                                   completion: TealiumCompletion?) {
        append(data, fileName: module, completion: completion)
    }

    /// Appends data to existing data of the same type.
    ///
    /// - Parameters:
    ///     - data: `Codable` object to be saved
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    public func append<T: Codable>(_ data: T,
                                   fileName: String,
                                   completion: TealiumCompletion?) {
        guard isDiskStorageEnabled else {
            // not supported if disk storage disabled
            log(error: DiskStorageErrors.diskStorageDisabled.rawValue)
            completion?(false, nil, nil)
            return
        }
        TealiumDiskStorage.readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            do {
                guard self.canWrite(data: data) == true else {
                    self.log(error: DiskStorageErrors.insufficientStorage.rawValue)
                    completion?(false, nil, nil)
                    return
                }
                try Disk.append(data, to: self.filePath(fileName), in: self.currentDirectory)
            } catch let error {
                completion?(false, nil, error)
            }
        }
    }

    /// Appends data to a `[String: Any]`.
    ///
    /// - Parameters:
    ///     - data: `[String: Any]` to be appended
    ///     - fileName: `String` containing the filename for the data to be saved
    ///     - completion: Optional completion to be called upon completion of the append operation
    public func append(_ data: [String: Any],
                       fileName: String,
                       completion: TealiumCompletion?) {
        TealiumDiskStorage.readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            do {
                let data = AnyCodable(data)
                try Disk.append(data, to: self.filePath(fileName), in: self.currentDirectory)
            } catch let error {
                completion?(false, nil, error)
            }
        }

    }

    /// Retrieves a `Decodable` item from disk storage.
    ///
    /// - Parameters:
    ///     - type: `T.Type` type of data to be retrieved
    ///     - completion: completion to be called upon retrieval
    public func retrieve<T: Decodable>(as type: T.Type) -> T? {
        retrieve(module, as: type)
    }

    /// Retrieves a `Decodable` item from disk storage.
    ///
    /// - Parameters:
    ///     - type: `T.Type` type of data to be retrieved
    ///     - fileName: `String` containing the filename for the data to be retrieved
    ///     - completion: completion to be called upon retrieval
    public func retrieve<T: Decodable>(_ fileName: String,
                                       as type: T.Type) -> T? {
        TealiumDiskStorage.readWriteQueue.read { [weak self] in
            guard let self = self else {
                return nil
            }
            guard isDiskStorageEnabled else {
                let decoder = Tealium.jsonDecoder
                if let data = self.getFromDefaults(key: self.filePath(fileName)) as? Data,
                   let decoded = try? decoder.decode(type, from: data) {
                    return decoded
                } else {
                    log(error: DiskStorageErrors.couldNotDecode.rawValue)
                    return nil
                }
            }
            do {
                let data = try Disk.retrieve(self.filePath(fileName), from: self.currentDirectory, as: type)
                return data
            } catch {
                return nil
            }
        }
    }

    /// Retrieves a `[String: Any]` from disk storage.
    ///
    /// - Parameters:
    ///     - fileName: `String` containing the filename for the data to be retrieved
    ///     - completion: completion to be called upon retrieval
    public func retrieve(fileName: String,
                         completion: TealiumCompletion) {
        TealiumDiskStorage.readWriteQueue.read { [weak self] in
            guard let self = self else {
                return
            }
            guard self.isDiskStorageEnabled else {
                let decoder = Tealium.jsonDecoder
                if let data = self.getFromDefaults(key: self.filePath(fileName)) as? Data,
                   let decoded = ((try? decoder.decode(AnyCodable.self, from: data).value as? [String: Any]) as [String: Any]??) {
                    completion(true, decoded, nil)
                } else {
                    log(error: DiskStorageErrors.couldNotDecode.rawValue)
                    completion(false, nil, nil)
                }
                return
            }
            do {
                guard let data = try Disk.retrieve(self.filePath(fileName), from: self.currentDirectory, as: AnyCodable.self).value as? [String: Any] else {
                    log(error: DiskStorageErrors.couldNotDecode.rawValue)
                    completion(false, nil, nil)
                    return
                }
                completion(true, data, nil)
            } catch let error {
                completion(false, nil, error)
            }
        }
    }

    /// Deletes all data for the current module.
    ///
    /// - Parameter completion: Completion block to be called upon deletion
    public func delete(completion: TealiumCompletion?) {
        TealiumDiskStorage.readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            guard self.isDiskStorageEnabled else {
                self.removeFromDefaults(key: self.filePath(self.module))
                return
            }
            do {
                try Disk.remove(self.filePath(self.module), from: self.currentDirectory)
                completion?(true, nil, nil)
            } catch let error {
                completion?(false, nil, error)
            }
        }
    }

    /// Updates a value for any `Codable` object representable as a `[String: Any]`.
    ///
    /// - Parameters:
    ///     - value: `Any` value to be set on the `Codable` object
    ///     - key: `String` representing the key to be updated on the codable object
    ///     - type: `T.Type` concrete type of the object to be updated
    ///     - completion: Optional compeletion block to be run after update
    public func update<T: Codable>(value: Any,
                                   for key: String,
                                   as type: T.Type,
                                   completion: TealiumCompletion?) {
        let data = retrieve(module, as: type.self)
        guard let encoded = try? Tealium.jsonEncoder.encode(data),
              let dictionary = ((try? JSONSerialization.jsonObject(with: encoded, options: .allowFragments) as? [String: Any]) as [String: Any]??),
              var dict = dictionary else {
            return
        }
        dict[key] = value
        let decoder = Tealium.jsonDecoder
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let newData = try? decoder.decode(T.self, from: jsonData) {
            save(newData, fileName: module, completion: completion)
        }
    }

    /// Saves a `String` value to UserDefaults.
    ///
    /// - Parameters:
    ///     - key: `String`
    ///     - value: `String`
    public func saveStringToDefaults(key: String,
                                     value: String) {
        defaultsStorage?.set(value, forKey: key)
    }

    /// Retrieves a `String` value from UserDefaults.
    ///
    /// - Parameter key: `String`
    /// - Returns: `String?`
    public func getStringFromDefaults(key: String) -> String? {
        defaultsStorage?.value(forKey: key) as? String
    }

    /// Saves `Any` value to UserDefaults.
    ///
    /// - Parameters:
    ///     - key: `String`
    ///     - value: `Any`
    public func saveToDefaults(key: String,
                               value: Any) {
        defaultsStorage?.set(value, forKey: key)
    }

    /// Retrieves `Any` value from UserDefaults
    ///
    /// - Parameter key: `String`
    /// - Returns: `Any?`
    public func getFromDefaults(key: String) -> Any? {
        defaultsStorage?.value(forKey: key)
    }

    /// Deletes a value from UserDefaults
    ///
    /// - Parameter key: `String`
    public func removeFromDefaults(key: String) {
        defaultsStorage?.removeObject(forKey: key)
    }

    /// - Parameter error: `String`
    func log(error: String) {
        //        logger.log(message: error, logLevel: .warnings)
        let logRequest = TealiumLogRequest(title: "DiskStorage", message: error, info: nil, logLevel: .error)
        logger?.log(logRequest)
    }

}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
