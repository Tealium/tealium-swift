//
//  TealiumStorageModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 4/26/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//
//  BRIEF: General purpose file persistence module using NSKeyedArchiver

import Foundation

enum TealiumFileStorageKey {
    static let moduleName = "filestorage"
}

enum TealiumFileStorageError : Error {

    case cannotWriteOrLoadFromDisk
    case noDataToSave
    case noSavedData
    case noFilename
    case malformedRequest
    case moduleNotEnabled
    
}

class TealiumFileStorageModule : TealiumModule {

    var filenamePrefix = ""
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumFileStorageKey.moduleName,
                                    priority: 350,
                                    build: 1,
                                    enabled: true)
    }
    
    override func handle(_ request: TealiumRequest) {
        
        if let r = request as? TealiumEnableRequest {
            enable(r)
        }
        else if let r = request as? TealiumDisableRequest {
            disable(r)
        }
        else if let r = request as? TealiumLoadRequest {
            load(r)
        }
        else if let r = request as? TealiumSaveRequest {
            save(r)
        }
        else if let r = request as? TealiumDeleteRequest {
            delete(r)
        }
        else {
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
            didFinish(request)
            return
        }
        
        guard let data = TealiumFileStorage.loadData(fromPath: path) else {
            // Persistent data requested doesn't exist at this time.
            request.completion?(false,
                                nil,
                                TealiumFileStorageError.noSavedData)
            didFinish(request)
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
    
    // TODO: Delete not working
    func delete(_ request: TealiumDeleteRequest) {

        if self.isEnabled == false {
            didFinish(request)
            return
        }
        
        let filepath = self.filenamePrefix.appending(".\(request.name)")

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
        let parentDir = "\(NSHomeDirectory())/.tealium/swift"
        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch _ as NSError {
            
            return nil
            
        }
        
        return "\(parentDir)/\(filename).data"
    }
    
    class func dataExists(atPath: String) -> Bool {
        
        return FileManager.default.fileExists(atPath: atPath)
        
    }
    
    class func loadData(fromPath: String) -> [String:Any]? {
        
        if dataExists(atPath: fromPath) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: fromPath) as? [String:Any]
        }
        
        return nil
        
    }
    
    class func save(data: [String:Any],
                    toPath: String) -> Bool {
        
        return NSKeyedArchiver.archiveRootObject(data, toFile: toPath)
        
    }
    
    class func deleteDataAt(path: String) -> Bool {
        
        if dataExists(atPath: path) == false {
            return true
        }
        
        do {
            try FileManager.default.removeItem(atPath: path)
            
        }
        catch _ as NSError {
            
            return false
        }
        
        return true
        
    }
    
}
