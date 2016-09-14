//
//  tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

class Tealium {
    
    let dataManager : TealiumDataManager
    private let logger : TealiumLogger
    private let config : TealiumConfig
    private let collect : TealiumCollect
    
    // MARK: PUBLIC
    
    /**
     Initializer.
     
     - Parameters:
        - TealiumConfig: Object created with Tealium account, profile, environment, optional loglevel)
     */
    init?(config: TealiumConfig){
        
        // Log system
        let loggerId = "\(config.account):\(config.profile):\(config.environment)"
        self.logger = TealiumLogger(loggerId: loggerId, logLevel: config.getLogLevel())
        
        // Data Manager
        guard let dataManager = TealiumDataManager(account: config.account, profile: config.profile, environment: config.environment) else {
            self.logger.log("Problem initializing the Data Manager: Check to that NSFileManager can write to disk", logLevel: .Errors)
            return nil
        }
        self.dataManager = dataManager
        
        // Collect dispatch service
        var urlString : String
        if let collectURLString = config.getOptionalData(tealiumKey_overrideCollectURL) as? String{
            urlString = collectURLString
        } else {
            urlString = TealiumCollect.defaultBaseURLString()
        }
        self.collect = TealiumCollect(baseURL: urlString)
        
        self.config = config
        
    }
   
    /**
     Convience method to track event with optional data .
     
     - Parameters:
        - Event Title: Required title of event )
        - Data: Optional dictionary for additional data sources to pass with call
        - Completion: Optional callback
     */
    func track(title: String,
               data: [String: AnyObject]?,
               completion: ((successful:Bool, encodedURLString: String, error: NSError?) -> Void)?) {
        
        var dataDictionary: [String : AnyObject] = [tealiumKey_event: title,
                                                    tealiumKey_event_name: title]
        
        
        dataDictionary += dataManager.getVolatileData()
        dataDictionary += dataManager.getPersistentData()!
        
        if data != nil  {
            dataDictionary += data!
        }
        
        collect.dispatch(dataDictionary, completion: completion)
        
    }
    
    /**
     Convience method to track events previously processed by the standard track(title, data, completion) method.
    
     - Parameters:
        - encodedURLString: Encoded string that will be used for the end point for the request
        - Completion: Optional callback
     */
    func track(encodedURLString: String,
               completion: ((success:Bool, encodedURLString: String, error: NSError?) -> Void)?) {
    
        collect.send(encodedURLString, completion: completion)
        
    }
 
    /**
     Retrieves data manager.
    
     - Returns:
        - TealiumDataManager class
    
     */
    func getDataManger() -> TealiumDataManager {

        return self.dataManager

    }
    
}


