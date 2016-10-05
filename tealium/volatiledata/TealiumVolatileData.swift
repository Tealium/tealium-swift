//
//  TealiumVolatileData.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumVolatileData {
    
    fileprivate var _volatileData = [String:AnyObject]()

    // MARK
    // MARK: PUBLIC
    
    /**
     Constructor.
     */
    required public init() {
        self.add(data:[TealiumVolatileDataKey.sessionId: newSessionId() as AnyObject])
    }
    
    /**
     Add data to all dispatches for the remainder of an active session.
     
     - parameters:
     - data: A [String:AnyObject] dictionary. Values should be of type String or [String]
     */
    public func add(data : [String:AnyObject]){
        
        _volatileData += data
        
    }
    
    /**
     Retrieve a copy of volatile data used with dispatches.
     
     - returns: A dictionary
     */
    public func getData() -> [String:AnyObject]{
        
        var data = [String:AnyObject]()
        data[TealiumVolatileDataKey.random] = getRandom() as AnyObject?
        data[TealiumVolatileDataKey.timestampEpoch] = getTimestampInSeconds() as AnyObject?
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
        self.add(data:[TealiumVolatileDataKey.sessionId: newSessionId() as AnyObject])
    }
    
    /// Manually set session id to a specified string
    ///
    /// - Parameter sessionId: String id to set session id to.
    public func setSessionId(sessionId: String) {
        self.add(data:[TealiumVolatileDataKey.sessionId: sessionId as AnyObject])
    }
    
    // MARK
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
