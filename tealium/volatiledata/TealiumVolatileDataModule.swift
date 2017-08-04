//
//  TealiumVolatileDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK:
// MARK: CONSTANTS

enum TealiumVolatileDataKey {
    static let moduleName = "volatiledata"
    static let random = "tealium_random"
    static let sessionId = "tealium_session_id"
    static let timestampEpoch = "tealium_timestamp_epoch"
}


// MARK:
// MARK: EXTENSIONS

extension Tealium {
    
    public func volatileData() -> TealiumVolatileData? {
        
        guard let module = modulesManager.getModule(forName: TealiumVolatileDataKey.moduleName) as? TealiumVolatileDataModule else {
            return nil
        }
        
        return module.volatileData
        
    }
    
}


// MARK:
// MARK: MODULE SUBCLASS

/// Module for adding session long (from wake until terminate) data varables to all track calls.
class TealiumVolatileDataModule : TealiumModule {
    
    var volatileData : TealiumVolatileData?
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumVolatileDataKey.moduleName,
                                   priority: 700,
                                   build: 2,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        let config = request.config
        if volatileData == nil {
            volatileData = TealiumVolatileData()
            let currentStaticData : [String:Any] = [TealiumKey.account:config.account,
                                                    TealiumKey.profile:config.profile,
                                                    TealiumKey.environment:config.environment,
                                                    TealiumKey.libraryName:TealiumValue.libraryName,
                                                    TealiumKey.libraryVersion:TealiumValue.libraryVersion]
          
            volatileData?.add(data: currentStaticData)
        }
        
        didFinish(request)
        
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        isEnabled = false
        volatileData = nil
        didFinish(request)
        
    }
    
    override func track(_ track: TealiumTrackRequest) {
        var newData = [String:Any]()
        
        if let volatileData = self.volatileData?.getData() {
            newData += volatileData
        }
        
        newData += track.data
        
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        
        didFinish(newTrack)
    }
    
}

// MARK:
// MARK: VOLATILE DATA

public class TealiumVolatileData {
    
    fileprivate var _volatileData = [String:Any]()
    
    // MARK: PUBLIC
    
    /**
     Constructor.
     */
    required public init() {
        
        self.add(data:[TealiumVolatileDataKey.sessionId: newSessionId() ])
        
    }
    
    /**
     Add data to all dispatches for the remainder of an active session.
     
     - parameters:
     - data: A [String:Any] dictionary. Values should be of type String or [String]
     */
    public func add(data : [String:Any]){
        
        _volatileData += data
        
    }
    
    /**
     Retrieve a copy of volatile data used with dispatches.
     
     - returns: A dictionary
     */
    public func getData() -> [String:Any]{
        
        var data = [String:Any]()
        
        data[TealiumVolatileDataKey.random] = getRandom()
        data[TealiumVolatileDataKey.timestampEpoch] = getTimestampInSeconds()
        data += _volatileData
        
        return data
    }
    
    /**
     Delete volatile data.
     
     - parameters:
     - keys: An array of String keys to remove from the internal volatile data store.
     */
    public func deleteData(forKeys:[String]){
        
        for key in forKeys {
            _volatileData.removeValue(forKey: key)
        }
        
    }
    
    /// Auto reset the session id now.
    public func resetSessionId() {
        
        self.add(data:[TealiumVolatileDataKey.sessionId: newSessionId() ])
    }
    
    /** Manually set session id to a specified string
     - Parameter sessionId: String id to set session id to.
     **/
    
    public func setSessionId(sessionId: String) {
        
        self.add(data:[TealiumVolatileDataKey.sessionId: sessionId ])
        
    }
    
    // MARK: INTERNAL
    
    internal func getRandom() -> String {
        
        let length = 16;
        var randomNumber: String = "";
        
        for _ in 1...length {
            let random = Int (arc4random_uniform(10))
            randomNumber+=String(random)
        }
        
        return randomNumber
    }
    
    internal func getTimestampInSeconds() -> String {
        
        let ts = Date().timeIntervalSince1970
        
        return "\(ts)"
    }
    
    
    internal func getTimestampInMilliseconds() -> String {
        
        let ts = Date().timeIntervalSince1970 * 1000
        
        return "\(ts)"
    }
    
    internal func newSessionId() -> String {
        return getTimestampInMilliseconds()
    }
    
    
    
    
}

