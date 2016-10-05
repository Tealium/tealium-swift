//
//  tealiumConfig.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//


// *****************************************
// MARK: Edit as Necessary
// Usable only with direct import
// *****************************************

let defaultTealiumConfig = TealiumConfig(account:"tealiummobile",
                                                profile:"demo",
                                                environment:"dev_qa_or_prod",
                                                optionalData:nil)


// *****************************************
// MARK: No need to edit below this line
// *****************************************

/*
 Configuration object for any Tealium instance.
 
 */
open class TealiumConfig {
    
    let account : String
    let profile : String
    let environment : String
    open var optionalData : [String:AnyObject]?
    
    /**
     Primary constructor.
     
     - parameters:
        - account: Tealium account name string to use.
        - profile: Tealium profile string.
        - environment: Tealium environment string.
        - optionalData: Optional [String:AnyObject] dictionary meant primarily for module use.
     */
    public init(account: String,
              profile: String,
              environment: String,
              optionalData: [String: AnyObject]?)  {
        
        self.account = account
        self.environment = environment
        self.profile = profile
        self.optionalData = optionalData
        
    }
    
    /**
         1.0.1 Support
     */
    @available(*, deprecated, message:"Access optional data property directly.")
    public func getOptionalData(key: String) -> AnyObject? {
        return optionalData?[key]
    }
    
    /**
        1.0.1 Support
     */
    @available(*, deprecated, message:"Set optional data property directly.")
    public func setOptionalData(key: String, value: AnyObject) {
        if optionalData == nil {
            optionalData = [String: AnyObject]()
        }
        optionalData?[key] = value
    }
}
