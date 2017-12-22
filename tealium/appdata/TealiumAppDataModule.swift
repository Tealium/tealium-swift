//
//  TealiumAppDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK:
// MARK: CONSTANTS
public enum TealiumAppDataKey {
    static let moduleName = "appdata"
    static let build = "app_build"
    static let name = "app_name"
    static let rdns = "app_rdns"
    static let uuid = "app_uuid"
    static let version = "app_version"
    static let visitorId = "tealium_visitor_id"
}

// MARK:
// MARK: MODULE SUBCLASS

/// Module to add app related data to track calls.
class TealiumAppDataModule : TealiumModule {
    
    var appData = [String:Any]()
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAppDataKey.moduleName,
                                   priority: 500,
                                   build: 3,
                                   enabled: true)
    }
    
     override func enable(_ request: TealiumEnableRequest) {

        let loadRequest = TealiumLoadRequest(name: TealiumAppDataModule.moduleConfig().name) { [weak self] (success, data, error) in
         
            // No prior saved data
            guard let loadedData = data else {
                self?.setNewAppData()
                return
            }
            
            // Loaded data does not contain expected keys
            if TealiumAppDataModule.isMissingPersistentKeys(loadedData) == true {
                self?.setNewAppData()
                return
            }
            
            self?.setLoadedAppData(loadedData)
        }
        
        delegate?.tealiumModuleRequests(module: self,
                                        process: loadRequest)

        // Little wonky here because what if a persistence modules is still in the
        //  process of returning data?
        isEnabled = true
        
        // We're not going to wait for the loadrequest to return because it may never
        //  if there are no persistence modules enabled.
        didFinish(request)
        
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        self.appData.removeAll()
        self.isEnabled = false
        didFinish(request)
        
    }
    
    override func track(_ track: TealiumTrackRequest) {
        
        if isEnabled == false {
            // Ignore this module
            didFinishWithNoResponse(track)
            return
        }
        
        // If no persistence modules enabled.
        if TealiumAppDataModule.isMissingPersistentKeys(appData) {            
            self.setNewAppData()
        }
    
        // Populate data stream
        var newData = [String:Any]()
        newData += appData
        newData += track.data
        
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        
        didFinish(newTrack)
        
    }
    
    // MARK:
    // MARK: INTERNAL
    
    class func isMissingPersistentKeys(_ data: [String:Any]) -> Bool {
        
        if data[TealiumAppDataKey.uuid] == nil {return true}
        if data[TealiumAppDataKey.visitorId] == nil {return true}
        return false
        
    }
    
    func newUuid() -> String {
        
        return UUID.init().uuidString
        
    }
    
    func visitorId(fromUuid: String) -> String {
        
        return fromUuid.replacingOccurrences(of: "-", with: "")
        
    }
    
    
    /// Prepares new Tealium default App related data. Legacy Visitor Id data
    /// is set here as it based off app_uuid.
    ///
    /// - Parameter forUuid: The uuid string to use for new persistent data.
    /// - Returns: A [String:Any] dictionary.
    func newPersistentData(forUuid: String) -> [String:Any]{
        
        let vid = visitorId(fromUuid: forUuid)
        
        let data = [
            TealiumAppDataKey.uuid: forUuid,
            TealiumAppDataKey.visitorId: vid
        ]
        
        return data as [String : Any]
    }
    
    func newVolatileData() -> [String:Any] {
        var result : [String:Any] = [:]
        let main = Bundle.main
        
        // Check & add
        if let name = main.infoDictionary?[kCFBundleNameKey as String] as? String {
            result[TealiumAppDataKey.name] = name
        }
        
        if let rdns = main.bundleIdentifier {
            result[TealiumAppDataKey.rdns] = rdns
        }
        
        if let version = main.infoDictionary?["CFBundleShortVersionString"] as? String {
            result[TealiumAppDataKey.version] = version
        }

        if let build = main.infoDictionary?[kCFBundleVersionKey as String] as? String {
            result[TealiumAppDataKey.build] = build
        }
        
        return result
        
    }
    
    func savePersistentData(_ data: [String:Any]) {
        
        let saveRequest = TealiumSaveRequest(name: TealiumAppDataModule.moduleConfig().name,
                                             data: data)
        
        delegate?.tealiumModuleRequests(module: self,
                                        process: saveRequest)
    }
    
    func setNewAppData() {
        
        let newUuid = self.newUuid()
        self.appData = self.newPersistentData(forUuid: newUuid)
        self.appData += newVolatileData()
        self.savePersistentData(self.appData)
        
    }
    
    func setLoadedAppData( _ data: [String:Any]) {
        self.appData = data
        self.appData += newVolatileData()
    }
    
}
