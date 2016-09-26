//
//  tealiumDataManager.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

// Extend the use of += operators to dictionaries
func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

// Extend use of == to dictionaries
func ==(lhs: [String: AnyObject], rhs: [String: AnyObject] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

/**
    Public Tealium Universal Data processing class.
 
 */
class TealiumDataManager {
    
    fileprivate let _account : String
    fileprivate let _profile : String
    fileprivate let _environment : String
    fileprivate var _persistentData : [String:AnyObject]?
    fileprivate var _volatileData = [String:AnyObject]()
    fileprivate var _ioManager  : TealiumIOManager
    
    
    // MARK: PUBLIC
    
    /**
        Initializer.
     
        - Parameters:
            - account: Required Tealium account name
            - profile: Required Tealium profile name (use 'main' if unsure)
            - environment: Required environment (usually dev/qa/prod)
     */
    init?(account: String, profile: String, environment: String){
        
        self._account = account
        self._profile = profile
        self._environment = environment
        guard  let ioManager = TealiumIOManager(account: _account, profile: _profile, env: _environment) else {
            return nil
        }
        
        self._ioManager = ioManager
        self.addVolatileData([tealiumKey_session_id: resetSessionId() as AnyObject])        
        self._persistentData = getPersistentData()
    
    }
    
    /**
        Add data to all dispatches that will be permanently saved.
     
        - Parameters:
            - data: A [String:AnyObject] dictionary. Values should be of type String or [String]
     */
    func addPersistentData(_ data : [String:AnyObject]){
        
        guard var persistentData = _persistentData else {return}
        persistentData += data
        _ioManager.saveData(persistentData)
        
    }
    
    /**
        Retrieve a copy of persistent data used with dispatches.
     
        - Returns: A dictionary
     */
    func getPersistentData() -> [String:AnyObject]? {
        
        if let data = self._persistentData {
            return data
        }
        
        if let data = self._ioManager.loadData(){
            return data
        }
        
        let data = newPersistentData()
        addPersistentData(data)
        return data
    
    }
    
    /**         
        Delete persistent data.
     
        - Parameters:
            - keys: An array of String keys to remove from the internal persistent data store.
     */
    func deletePersistentData(_ keys:[String]){
        
        for key in keys {
           let _ = _persistentData?.removeValue(forKey: key)
        }
        
    }
    
    /**
        Add data to all dispatches for the remainder of an active session.
     
        - Parameters:
            - data: A [String:AnyObject] dictionary. Values should be of type String or [String]
     */
    func addVolatileData(_ data : [String:AnyObject]){
        
        _volatileData += data
        
    }
    
    /**
        Retrieve a copy of volatile data used with dispatches.
     
        - Returns: A dictionary
     */
    func getVolatileData() -> [String:AnyObject]{
        
        var data = [String:AnyObject]()
        data[tealiumKey_random] = getRandom() as AnyObject?
        data[tealiumKey_timestamp_epoch] = getTimestampInSeconds() as AnyObject?
        data += _volatileData
        
        return data
    }
    
    /**
        Delete volatile data.
    
        - Parameters:
            - keys: An array of String keys to remove from the internal volatile data store.
    */
    func deleteVolatileData(_ keys:[String]){
        
        for key in keys {
            _volatileData.removeValue(forKey: key)
        }
        
    }
    
    // MARK: INTENDED FOR PRIVATE
    
    func getLibraryInfo() -> [String:AnyObject]{
        
        let info = [tealiumKey_library_name : tealiumValue_library_name,
                    tealiumKey_library_version : tealiumValue_library_version
                    ]
        self.addPersistentData(info as [String : AnyObject])

        return info as [String : AnyObject]
    }
    
    func getAccountInfo() -> [String:AnyObject]{
        
        let info = [tealiumKey_account : _account,
                    tealiumKey_profile : _profile,
                     tealiumKey_environment : _environment
                   ]
        return info as [String : AnyObject]
    }

    func getRandom() -> String {
        
        let length = 16;
        var randomNumber: String = "";
        
        for _ in 1...length {
            let random = Int (arc4random_uniform(10))
            randomNumber+=String(random)
        }
        
        return randomNumber
    }
    
    func resetSessionId() -> String {
        return getTimestampInMilliseconds()
    }
    
    func getTimestampInSeconds() -> String {

        let ts = Date().timeIntervalSince1970
        
        return "\(ts)"
    }
    
    
    func getTimestampInMilliseconds() -> String {
        
        let ts = Date().timeIntervalSince1970 * 1000
        
        return "\(ts)"
    }

    
    func newVisitorId() -> String {
        
        var vid = UUID.init().uuidString
        vid = vid.replacingOccurrences( of: "-" , with: "")
        
        return vid
    }
    
    func newPersistentData() -> [String:AnyObject]{
        
        let vid = newVisitorId()
        
        let data = [tealiumKey_account:_account,
                    tealiumKey_profile: _profile,
                    tealiumKey_environment: _environment,
                    tealiumKey_library_name: tealiumValue_library_name,
                    tealiumKey_library_version: tealiumValue_library_version,
                    tealiumKey_visitor_id: vid,
                    tealiumKey_legacy_vid: vid]
        
        return data as [String : AnyObject]
    }
    
}
