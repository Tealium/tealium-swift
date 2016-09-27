//
//  tealiumConfig.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

/**
    Public Configuration object for Tealium instances.
 
 */
class TealiumConfig {
    
    var account : String!
    var profile : String!
    var environment : String!
    fileprivate let logLevelDefault : LogLevel = .verbose
    fileprivate let logLevelKey = "logLevel"
    fileprivate var _optionalData : [ String : AnyObject ]?

    // MARK: PUBLIC
    
    /**
        Initializer.
     
        - Parameters:
            - account: Tealium account name
            - profile: Tealium profile name
            - environment : Tealium environment to use (usually dev/qa/prod)
     */
    init(account: String, profile: String, environment: String){
    
        self.account = account
        self.profile = profile
        self.environment = environment
        
    }

    /**
        Convenience method for setting log level output from the library.
     
        - Paramaters:
            - logLevel: The level to use (None/Errors/Warnings/Verbose)
     */
    func setLogLevel(_ logLevel: LogLevel){
        self.setOptionalData(logLevelKey, value: logLevel.description as AnyObject)
    }
    
    /**
        Get the log level setting for this config.
     
        - Returns: The current log level enum
     */
    func getLogLevel() -> LogLevel {
        
        guard let logLevelString = getOptionalData(logLevelKey) as? String else {
            return logLevelDefault
        }
        return LogLevel.fromString(logLevelString)
    }
    
    /**
        Adds optional configuration data. Meant for future extensions.
     
        - Paramaters:
            - key: Unique string identifier for data
            - value: Data to be stored
     */
    func setOptionalData(_ key: String, value: AnyObject) {
        if self._optionalData == nil {
            self._optionalData = [String: AnyObject]()
        }
        self._optionalData?[key] = value
    }
    
    /**
        Retrieves optional data. Meant for future extensions.
     
        - Parameters:
            - key: String identifier for the data value desired
    */
    func getOptionalData( _ key : String) -> AnyObject? {
        return self.optionalData()[key]
    }
    
    
    // MARK: PRIVATE
    
    fileprivate func optionalData() -> [String : AnyObject]{
        guard let extData = self._optionalData else {
            return [String: AnyObject]()
        }
        return extData
    }
    
}
