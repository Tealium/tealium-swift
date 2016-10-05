//
//  tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

/**
    Public interface for the Tealium library.
 */
class Tealium {
    
    /// Mediator for all Tealium modules.
    let modulesManager : TealiumModulesManager
    
    // MARK: PUBLIC
    /**
     Initializer.
     
     - parameters:
        - tealiumConfig: Object created with Tealium account, profile, environment, optional loglevel)
     */
    init(config: TealiumConfig){
        
        modulesManager = TealiumModulesManager(config: config)
        modulesManager.updateAll()
        
    }
    
    /**
     Used after disable() to re-enable library activites. Unnecessary to call after
     initial init. Does NOT override individual module enabled flags.
     */
    func enable(){
        modulesManager.updateAll()
    }
    
    /**
     Suspends all library activity, may release internal objects.
     */
    func disable(){
        modulesManager.disableAll()
    }
   
    /**
     Convenience method to track general events.
     
    - parameters:
        - event Title: Required title of event.
        - data: Optional dictionary for additional data sources to pass with call.
        - completion: Optional callback.
        - successful: Wether completion succeeded or encountered a failure.
        - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
        - error: Error encountered, if any.
     */
    func track(title: String,
               data: [String: AnyObject]?,
               completion: ((_ successful:Bool, _ info:[String:AnyObject]?, _ error: Error?) -> Void)?) {
        
        // Default type is .activity
        modulesManager.track(type: TealiumTrackType.activity,
                             title: title,
                             data: data,
                             info: nil,
                             completion: completion)
        
    }
    
    /**
     Primary track method specifying tealium event type.
     
     - parameters:
         - type: TealiumTrackType - view/activity/interaction/derived/conversion.
         - event Title: Required title of event.
         - data: Optional dictionary for additional data sources to pass with call.
         - completion: Optional callback.
         - successful: Wether completion succeeded or encountered a failure.
         - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
         - error: Error encountered, if any.
     */
    func track(type: TealiumTrackType,
               title: String,
               data: [String: AnyObject]?,
               completion: ((_ successful:Bool, _ info:[String:AnyObject]?, _ error: Error?) -> Void)?) {
        
        modulesManager.track(type: type,
                             title: title,
                             data: data,
                             info: nil,
                             completion: completion)
        
    }}


