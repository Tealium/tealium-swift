//
//  UserDefaults_Migration.swift
//  tealium-swift
//
//  Created by Craig Rouse on 05/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumLegacyMigrator: TealiumLegacyMigratorProtocol {

    var defaultsKey: String
    var filePath: String?

    private init(forModule module: String) {
        defaultsKey = "com.tealium.defaultsstorage.\(module)"
        filePath = path(filename: module)
    }

    /// Retrieves data from legacy FileStorage or DefaultsStorage modules.￼
    ///
    /// - Parameter module: `String` containing the module name for which to retrieve data
    /// - Returns: `[String: Any]?` containing any data found for the module
    public static func getLegacyData(forModule module: String) -> [String: Any]? {
        return TealiumLegacyMigrator(forModule: module).getLegacyData()
    }

    /// Retrieves data from legacy FileStorage or DefaultsStorage modules.￼
    ///
    /// - Parameter module: `String` containing the module name for which to retrieve data
    /// - Returns: `[[String: Any]]?` containing any data found for the module
    public static func getLegacyDataArray(forModule module: String) -> [[String: Any]]? {
        return TealiumLegacyMigrator(forModule: module).getLegacyDataArray()
    }

    /// Retrieves data from legacy FileStorage or DefaultsStorage modules.
    ///
    /// - Returns: `[String: Any]?` containing any data found for the module
    func getLegacyData() -> [String: Any]? {
        if let data = loadDataFromDefaults(forKey: defaultsKey) {
            return data
        } else if let filePath = filePath,
            let data = loadData(fromPath: filePath) {
            return data
        }

        return nil
    }

    /// Retrieves data from legacy FileStorage or DefaultsStorage modules.
    ///
    /// - Returns: `[String: Any]?` containing any data found for the module
    func getLegacyDataArray() -> [[String: Any]]? {
        if let data = loadArrayDataFromDefaults(forKey: defaultsKey) {
            return data
        } else if let filePath = filePath,
            let data = loadArrayData(fromPath: filePath) {
            return data
        }

        return nil
    }

    // MARK: Defaults Storage Migration

    /// Retrieves data from legacy DefaultsStorage.
    /// Automatically removes data when found, to avoid duplicate migration.
    ///
    /// - Returns: `[String: Any]?` containing any data found for the module
    func loadDataFromDefaults(forKey key: String) -> [String: Any]? {
        if let data = UserDefaults.standard.dictionary(forKey: key) {
            UserDefaults.standard.removeObject(forKey: key)
            return data
        }
        return nil
    }

    /// Retrieves data from legacy DefaultsStorage.
    /// Automatically removes data when found, to avoid duplicate migration.
    ///
    /// - Returns: `[[String: Any]]?` containing any data found for the module
    func loadArrayDataFromDefaults(forKey key: String) -> [[String: Any]]? {
        if let data = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
            UserDefaults.standard.removeObject(forKey: key)
            return data
        }
        return nil
    }

    // MARK: File Storage Migration

    /// - Returns: `Bool` `true` if file exists
    func fileExists(at path: String) -> Bool {

        return FileManager.default.fileExists(atPath: path)
    }

    /// Generates legacy filename for the current module￼.
    ///
    /// - Parameters:
    ///     - config: `TealiumConfig`￼
    ///     - fileName: `String` containing the file name to be prefixed
    func filename(config: TealiumConfig,
                  fileName: String) -> String {

        let prefix = "\(config.account).\(config.profile).\(config.environment)"

        return prefix.appending(".\(fileName)")
    }

    /// Attempts to load data for the current module from the specified path￼.
    ///
    /// - Parameter path: `String` representing the file path
    /// - Returns: `[String: Any]?` containing any data found for the module
    func loadData(fromPath path: String) -> [String: Any]? {

        if fileExists(at: path) {
            let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [String: Any]
            try? FileManager.default.removeItem(atPath: path)
            return data
        }

        return nil
    }

    /// Attempts to load data for the current module from the specified path￼.
    /// 
    /// - Parameter path: `String` representing the file path
    /// - Returns: `[[String: Any]]?` containing any data found for the module
    func loadArrayData(fromPath path: String) -> [[String: Any]]? {

        if fileExists(at: path) {
            let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [[String: Any]]
            try? FileManager.default.removeItem(atPath: path)
            return data
        }

        return nil
    }

    /// Gets path for filename.
    ///￼
    /// - Parameter filename: Filename of data file.
    /// - Returns: String if path can be created. Nil otherwise.
    func path(filename: String) -> String? {
        let parentDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let path = ".tealium/swift"
        let dirURL = URL(fileURLWithPath: path, relativeTo: parentDir[0])
        let fullPath = dirURL.path
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        } catch _ as NSError {
            // could not create directory. check permissions
            return nil
        }
        return "\(fullPath)/\(filename).data"
    }

}

// Allows overriding migrator for unit tests
public protocol TealiumLegacyMigratorProtocol {
    static func getLegacyData(forModule module: String) -> [String: Any]?
    static func getLegacyDataArray(forModule module: String) -> [[String: Any]]?
}
