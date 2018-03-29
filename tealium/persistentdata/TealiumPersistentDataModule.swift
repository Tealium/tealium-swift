//
//  TealiumDataManagerModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

public enum TealiumPersistentKey {
    static let moduleName = "persistentdata"
}

// MARK: 
// MARK: EXTENSIONS
public extension Tealium {

    /**
     Get the Data Manager instance for accessing file persistence and auto data variable APIs.
     */
    func persistentData() -> TealiumPersistentData? {
        guard let module = modulesManager.getModule(forName: TealiumPersistentKey.moduleName) as? TealiumPersistentDataModule else {
            return nil
        }

        return module.persistentData
    }

}

// MARK: 
// MARK: MODULE SUBCLASS

/**
 Module for adding publically accessible persistence data capability.
 */
class TealiumPersistentDataModule: TealiumModule {

    var persistentData: TealiumPersistentData?

    override class func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumPersistentKey.moduleName,
                                    priority: 600,
                                    build: 2,
                                    enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        self.persistentData = TealiumPersistentData(delegate: self)
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        persistentData?.persistentDataCache.removeAll()
        persistentData = nil
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {
        if self.isEnabled == false {
            didFinish(track)
            return
        }

        guard let persistentData = self.persistentData else {
            // Unable to load persistent data - continue with track call
            // TODO: Error reporting?
            didFinish(track)
            return
        }

        if persistentData.persistentDataCache.isEmpty {
            // No custom persistent data to load
            didFinish(track)
            return
        }

        var dataDictionary = [String: Any]()

        dataDictionary += persistentData.persistentDataCache
        dataDictionary += track.data
        let newTrack = TealiumTrackRequest(data: dataDictionary,
                                           completion: track.completion)

        didFinish(newTrack)
    }

}

extension TealiumPersistentDataModule: TealiumPersistentDataDelegate {

    func requestLoad(completion: @escaping TealiumCompletion) {
        let request = TealiumLoadRequest(name: TealiumPersistentKey.moduleName,
                                         completion: completion)
        delegate?.tealiumModuleRequests(module: self,
                                        process: request)
    }

    func requestSave(data: [String: Any]) {
        let request = TealiumSaveRequest(name: TealiumPersistentKey.moduleName,
                                         data: data)
        delegate?.tealiumModuleRequests(module: self,
                                        process: request)
    }

}

// MARK: 
// MARK: PERSISTENT DATA

protocol TealiumPersistentDataDelegate: class {
    func requestSave(data: [String: Any])
    func requestLoad(completion: @escaping TealiumCompletion)
}

public class TealiumPersistentData {

    var persistentDataCache = [String: Any]()
    weak var delegate: TealiumPersistentDataDelegate?

    init(delegate: TealiumPersistentDataDelegate) {
        self.delegate = delegate
        self.delegate?.requestLoad(completion: { [weak self] _, data, _ in

            // TODO: Better error handling
            guard let savedData = data else {
                // No data to load
                return
            }

            self?.persistentDataCache += savedData
        })
    }

    /// Add additional persistent data that will be available to all track calls
    ///     for lifetime of app. Values will overwrite any pre-existing values
    ///     for a given key.
    ///
    /// - Parameter data: [String:Any] of additional data to add.
    public func add(data: [String: Any]) {
        persistentDataCache += data

        delegate?.requestSave(data: persistentDataCache)
    }

    /// Delete a saved value for a given key.
    ///
    /// - Parameter forKeys: [String] Array of keys to remove.
    public func deleteData(forKeys: [String]) {
        var cacheCopy = persistentDataCache

        for key in forKeys {
            cacheCopy.removeValue(forKey: key)
        }

        persistentDataCache = cacheCopy

        delegate?.requestSave(data: persistentDataCache)
    }

    /**
     Delete all custom persisted data for current library instance.
     
     */
    public func deleteAllData() {
        persistentDataCache.removeAll()

        delegate?.requestSave(data: persistentDataCache)
    }

}
