//
//  tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Build 2

import Foundation

/**
    Public interface for the Tealium library.
 */
open class Tealium {
    
    /// Mediator for all Tealium modules.
    let modulesManager : TealiumModulesManager
    
    // MARK: PUBLIC
    /**
     Initializer.
     
     - parameters:
        - tealiumConfig: Object created with Tealium account, profile, environment, optional loglevel)
     */
    public init(config: TealiumConfig){
        
        modulesManager = TealiumModulesManager(config: config)
        modulesManager.updateAll()
        
    }
    
    /**
     Used after disable() to re-enable library activites. Unnecessary to call after
     initial init. Does NOT override individual module enabled flags.
     */
    open func enable(){
        modulesManager.updateAll()
    }
    
    /**
     Suspends all library activity, may release internal objects.
     */
    open func disable(){
        modulesManager.disableAll()
    }
   
    /**
     Convenience method to track general events.
     
    - parameters:
        - event Title: Required title of event.
        - data: Optional dictionary for additional data sources to pass with call.
        - completion: Optional callback that is returned IF a dispatch service has delivered a call.
            - successful: Wether completion succeeded or encountered a failure.
            - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
            - error: Error encountered, if any.
     */
    open func track(title: String,
               data: [String: Any]?,
               completion: ((_ successful:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?) {
        
        self.track(type: .activity,
                   title: title,
                   data: data,
                   completion: completion)
    }
    
    /**
     Primary track method specifying tealium event type.
     
     - parameters:
         - type: TealiumTrackType - view/activity/interaction/derived/conversion.
         - event Title: Required title of event.
         - data: Optional dictionary for additional data sources to pass with call.
         - completion: Optional callback that is returned IF a dispatch service has delivered a call.
             - successful: Wether completion succeeded or encountered a failure.
             - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
             - error: Error encountered, if any.
     */
    open func track(type: TealiumTrackType,
               title: String,
               data: [String: Any]?,
               completion: ((_ successful:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?) {
        
        let trackData = Tealium.trackDataFor(type: type,
                                             title: title,
                                             optionalData: data)
        let track = TealiumTrack(data: trackData,
                                 info: nil,
                                 completion: completion)
        
        modulesManager.track(track)
        
    }
    
    
    /// Convenience data packaging for Tealium track types & titles.
    ///
    /// - Parameters:
    ///   - type: TealiumTrackType to use.
    ///   - title: String description for track name.
    ///   - optionalData: Optional key-values for TIQ variables / UDH attributes
    /// - Returns: Dictionary of type [String:Any]
    open class func trackDataFor(type: TealiumTrackType,
                                 title: String,
                                 optionalData: [String:Any]?) -> [String:Any] {
        
        // ? Needed derefencing to incoming args.
        let newTitle = title
        let newType = type
        let newOptionalData = optionalData
        
        var trackData : [String:Any] = [TealiumKey.event: newTitle ,
                                        TealiumKey.eventName: newTitle ,
                                        TealiumKey.eventType: newType.description() ]
        if let clientOptionalVariables = newOptionalData {
            trackData += clientOptionalVariables
        }
        
        return trackData
    }
}



