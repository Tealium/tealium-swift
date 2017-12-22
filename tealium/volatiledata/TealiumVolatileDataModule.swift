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
    static let timestamp = "event_timestamp_iso"
    static let timestampLocal = "event_timestamp_local_iso"
    static let timestampOffset = "event_timestamp_offset_hours"
    static let timestampUnix = "event_timestamp_unix_millis"
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
    
    var volatileData = TealiumVolatileData()
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumVolatileDataKey.moduleName,
                                   priority: 700,
                                   build: 3,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        let config = request.config
        let currentStaticData : [String:Any] = [TealiumKey.account:config.account,
                                                TealiumKey.profile:config.profile,
                                                TealiumKey.environment:config.environment,
                                                TealiumKey.libraryName:TealiumValue.libraryName,
                                                TealiumKey.libraryVersion:TealiumValue.libraryVersion,
                                                TealiumVolatileDataKey.sessionId: volatileData.newSessionId()]
      
        volatileData.add(data: currentStaticData)
        
        didFinish(request)
        
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        isEnabled = false
        volatileData.deleteAllData()
        didFinish(request)
        
    }
    
    override func track(_ track: TealiumTrackRequest) {
        var newData = [String:Any]()
        
        newData += volatileData.getData()
        newData += track.data
        
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        
        didFinish(newTrack)
    }
    
}

// MARK:
// MARK: VOLATILE DATA

public class TealiumVolatileData : NSObject {
    
    fileprivate var _volatileData = [String:Any]()
    
    // MARK: PUBLIC
    
    /**
     Constructor.
     */
//    required public override init() {
//        
//        self.add(data:[TealiumVolatileDataKey.sessionId: newSessionId() ])
//        
//    }
    
    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    /**
     Add data to all dispatches for the remainder of an active session.
     
     - parameters:
     - data: A [String:Any] dictionary. Values should be of type String or [String]
     */
    public func add(data : [String:Any]){
        sync(lock: self) {
            _volatileData += data
        }
    }
    
    /**
     Retrieve a copy of volatile data used with dispatches.
     
     - returns: A dictionary
     */
    public func getData() -> [String:Any]{
        
        var data = [String:Any]()
        
        data[TealiumVolatileDataKey.random] = getRandom()
        data.merge(currentTimeStamps()) { (_, new) -> Any in
            new
        }
        data[TealiumVolatileDataKey.timestampOffset] = timezoneOffset()
        data += _volatileData
        
        return data
    }
    
    /**
     Delete volatile data.
     
     - parameters:
     - keys: An array of String keys to remove from the internal volatile data store.
     */
    public func deleteData(forKeys:[String]){
        sync(lock: self) {
            for key in forKeys {
                _volatileData.removeValue(forKey: key)
            }
        }
        
    }
    /**
     Delete all volatile data.
     */
    public func deleteAllData() {
        sync(lock: self) {
            for key in _volatileData.keys {
                    _volatileData.removeValue(forKey: key)
            }
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
    
    internal func getTimestampInSeconds(_ date: Date) -> String {
        
        let ts = date.timeIntervalSince1970
        
        return "\(Int(ts))"
    }
    
    
    internal func getTimestampInMilliseconds(_ date: Date) -> String {
        
        let ts = date.unixTime
        
        return ts
    }
    
    internal func newSessionId() -> String {
        return getTimestampInMilliseconds(Date())
    }
    
    internal func currentTimeStamps() -> [String: Any] {
        /** having this in a single function guarantees we're sending the exact same timestamp,
            as the date object only gets created once **/
        let date = Date()
        return [
            TealiumVolatileDataKey.timestampEpoch : getTimestampInSeconds(date),
            TealiumVolatileDataKey.timestamp : getDate8601UTC(date),
            TealiumVolatileDataKey.timestampLocal : getDate8601Local(date),
            TealiumVolatileDataKey.timestampUnix: date.unixTime
        ]
    }
    
    internal func getDate8601Local(_ date: Date) -> String {
        return date.iso8601LocalString
    }
    
    internal func getDate8601UTC(_ date: Date) -> String {
        return date.iso8601String
    }
    
    internal func timezoneOffset() -> String {
        let tz = TimeZone.current
        let offsetSeconds = tz.secondsFromGMT()
        let offsetHours = offsetSeconds/3600
        return String(format: "%i", offsetHours)
    }
}

