//
//  TealiumStorageModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 4/26/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

//  BRIEF: General purpose file persistence module using NSKeyedArchiver

import Foundation

enum TealiumFileStorageKey {
    static let moduleName = "filestorage"
}

enum TealiumFileStorageError: Error {

    case cannotWriteOrLoadFromDisk
    case noDataToSave
    case noSavedData
    case noFilename
    case malformedRequest
    case moduleNotEnabled

}

extension TealiumFileStorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cannotWriteOrLoadFromDisk:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: cannotWriteOrLoadFromDisk: Could not write to or load from disk.", comment: "")
        case .noDataToSave:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: noDataToSave", comment: "")
        case .noSavedData:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: noSavedData: Data could not be loaded from persistent storage. If this is a 1st launch, or no prior data has been set, then disregard this warning.", comment: "")
        case .noFilename:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: noFileName", comment: "")
        case .malformedRequest:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: malformedRequest", comment: "")
        case .moduleNotEnabled:
            return NSLocalizedString("\(TealiumFileStorageKey.moduleName) Error: moduleNotEnabled", comment: "")
        }
    }
}

class TealiumFileStorageModule: TealiumModule {

    var filenamePrefix = ""

    override class func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumFileStorageKey.moduleName,
                                    priority: 350,
                                    build: 1,
                                    enabled: true)
    }

    override func handle(_ request: TealiumRequest) {

        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumLoadRequest {
            load(request)
        } else if let request = request as? TealiumSaveRequest {
            save(request)
        } else if let request = request as? TealiumDeleteRequest {
            delete(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func enable(_ request: TealiumEnableRequest) {

        isEnabled = true
        filenamePrefix = TealiumFileStorageModule.filenamePrefix(config: request.config)
        didFinish(request)

    }

    func load(_ request: TealiumLoadRequest) {

        if self.isEnabled == false {
            didFailToFinish(request,
                            error: TealiumFileStorageError.moduleNotEnabled)
            return
        }

        let baseFilename = request.name

        let filename = self.filenamePrefix.appending(".\(baseFilename)")

        guard let path = TealiumFileStorage.path(filename: filename) else {
            // Path could not be created. Let requesting module know.
            request.completion?(false,
                                nil,
                                TealiumFileStorageError.cannotWriteOrLoadFromDisk)
            // Pass load request back to module manager - perhaps another module
            //   can provide the requested data.
            didFinish(request, TealiumFileStorageError.cannotWriteOrLoadFromDisk)
            return
        }

        guard let data = TealiumFileStorage.loadData(fromPath: path) else {
            // Persistent data requested doesn't exist at this time.
            request.completion?(false,
                                nil,
                                TealiumFileStorageError.noSavedData)

            didFinish(request, TealiumFileStorageError.noSavedData)
            return
        }

        // Data available, pass it back to the requesting module.
        request.completion?(true,
                            data,
                            nil)
        didFinish(request)

    }

    // TODO: New requests aren't overwriting existing
    func save(_ request: TealiumSaveRequest) {

        if self.isEnabled == false {
            didFinish(request)
            return
        }

        let baseFilename = request.name

        let filename = self.filenamePrefix.appending(".\(baseFilename)")

        guard let path = TealiumFileStorage.path(filename: filename) else {
            // Path could not be created. Let requesting module know.
            request.completion?(false,
                                nil,
                                TealiumFileStorageError.cannotWriteOrLoadFromDisk)
            // Pass save request back to module manager - perhaps another module
            //   can provide the requested data.
            didFinish(request)
            return
        }

        let data = request.data

        let wasSuccessful = TealiumFileStorage.save(data: data,
                                                    toPath: path)

        request.completion?(wasSuccessful,
                            data,
                            nil)

        didFinish(request)
    }

    func delete(_ request: TealiumDeleteRequest) {

        if self.isEnabled == false {
            didFinish(request)
            return
        }

        let fileName = self.filenamePrefix.appending(".\(request.name)")

        guard let filepath = TealiumFileStorage.path(filename: fileName) else {
            request.completion?(false,
                                nil,
                                TealiumFileStorageError.cannotWriteOrLoadFromDisk)
            // should never get here, but possible if permissions issues
            didFailToFinish(request, error: TealiumFileStorageError.cannotWriteOrLoadFromDisk)
            return
        }

        let success = TealiumFileStorage.deleteDataAt(path: filepath)

        request.completion?(success,
                            nil,
                            success ? nil : TealiumFileStorageError.cannotWriteOrLoadFromDisk)

        didFinish(request)
    }

    /// Returns filename prefix to distinguish module persistence files by origin
    ///   accounts. Supports multi-lib instances and legacy 1.0.0-1.2.0 naming
    ///   scheme.
    ///
    /// - Parameter config: TealiumConfig object used to init lib instance.
    /// - Returns: Account unique id string.
    class func filenamePrefix(config: TealiumConfig) -> String {
        let prefix = "\(config.account).\(config.profile).\(config.environment)"
        return prefix
    }
}

class TealiumFileStorage {

    /// Gets path for filename.
    ///
    /// - Parameter filename: Filename of data file.
    /// - Returns: String if path can be created. Nil otherwise.
    class func path(filename: String) -> String? {
        // Using the same parent path as lib versions prior to 1.3.0. Updating this
        //  path with subfolders for specific configs more ideal. We're going
        //  to prefix the filename instead because we have to do that for legacy
        //  support anyways. As there are few modules requiring persistence
        //  and multiple library instances are uncommon, this should suffice.
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

    class func dataExists(atPath: String) -> Bool {

        return FileManager.default.fileExists(atPath: atPath)

    }

    class func loadData(fromPath: String) -> [String: Any]? {

        if dataExists(atPath: fromPath) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: fromPath) as? [String: Any]
        }

        return nil

    }

    class func save(data: [String: Any],
                    toPath: String) -> Bool {

        return NSKeyedArchiver.archiveRootObject(data, toFile: toPath)

    }

    class func deleteDataAt(path: String) -> Bool {

        if dataExists(atPath: path) == false {
            return true
        }

        do {
            try FileManager.default.removeItem(atPath: path)

        } catch _ as NSError {

            return false
        }

        return true

    }

}
