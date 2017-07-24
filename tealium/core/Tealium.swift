//
//  tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Build 3

import Foundation

/**
    Public interface for the Tealium library.
 */
public class Tealium {
    
    /// Mediator for all Tealium modules.
    let modulesManager : TealiumModulesManager
    
    // MARK: PUBLIC
    /**
     Initializer.
     
     - parameters:
        - tealiumConfig: Object created with Tealium account, profile, environment, optional loglevel)
     */
    init(config: TealiumConfig){
        
        modulesManager = TealiumModulesManager()
        modulesManager.setupModulesFrom(config: config)
        modulesManager.enable(config: config)
        
    }
    
    /**
      Enablement call used after disable() to re-enable library activites. Unnecessary to call after
     initial init. Does NOT override individual module enabled flags.
     */
    func enable(){
        guard let currentConfig = modulesManager.config else {
            // No pre-existing configuration available.
            return
        }
        modulesManager.enable(config: currentConfig)
    }
    
    /**
     Update an actively running library with new configuration object.
     
        - Parameter config: TealiumConfiguration to update library with.
     **/
    func update(config: TealiumConfig){
        modulesManager.update(config: config)
    }
    
    /**
     Suspends all library activity, may release internal objects.
     */
    func disable(){
        modulesManager.disable()
    }
   
    
    /// Convenience track method with only a title argument.
    ///
    /// - Parameter title: String name of the event. This converts to 'tealium_event'
    
    func track(title: String) {
        
        self.track(title: title,
                   data: nil,
                   completion: nil)
        
    }
    
    /**
     Primary track method specifying tealium event type.
     
    - parameters:
        - event Title: Required title of event.
        - data: Optional dictionary for additional data sources to pass with call.
        - completion: Optional callback that is returned IF a dispatch service has delivered a call. Note this callback will be returned for every dispatch service module enabled.
            - successful: Wether completion succeeded or encountered a failure.
            - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
            - error: Error encountered, if any.
     */
    func track(title: String,
               data: [String: Any]?,
               completion: ((_ successful:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?) {
        
        let trackData = Tealium.trackDataFor(title: title,
                                             optionalData: data)
        let track = TealiumTrackRequest(data: trackData,
                                        completion: completion)
        
        modulesManager.track(track)
    }
    
    /**
     Deprecated track method specifying tealium event type.
     
     - parameters:
         - type: TealiumTrackType - view/activity/interaction/derived/conversion.
         - event Title: Required title of event.
         - data: Optional dictionary for additional data sources to pass with call.
         - completion: Optional callback that is returned IF a dispatch service has delivered a call.
             - successful: Wether completion succeeded or encountered a failure.
             - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
             - error: Error encountered, if any.
     */
    @available(*, deprecated, message: "Track Type no longer necessary. This method will be removed next version.")
    func track(type: TealiumTrackType,
               title: String,
               data: [String: Any]?,
               completion: ((_ successful:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?) {
        
        track(title: title,
              data: data,
              completion: completion)
        
    }
    
    
    /// Packages a track title and any custom client data for Tealium track requests. 
    ///     Calling this method directly generally not needed but could be used to
    ///     confirm the client added data payload that will be added to the Tealium 
    ///     data layer prior to dispatch.
    ///
    /// - Parameters:
    ///   - type: TealiumTrackType to use.
    ///   - title: String description for track name.
    ///   - optionalData: Optional key-values for TIQ variables / UDH attributes
    /// - Returns: Dictionary of type [String:Any]
    class func trackDataFor(title: String,
                            optionalData: [String:Any]?) -> [String:Any] {
        
        // ? Needed derefencing to incoming args.
        let newTitle = title
        let newOptionalData = optionalData
        
        var trackData : [String:Any] = [TealiumKey.event: newTitle]
        
        if let clientOptionalVariables = newOptionalData {
            trackData += clientOptionalVariables
        }
        
        return trackData
    }
}



