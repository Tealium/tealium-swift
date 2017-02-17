//
//  TealiumCollectModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

extension Tealium {
    
    /**
     Deprecated - use the track(title: String, data: [String:Any]?, completion:((_ success: Bool, _ error: Error?)->Void) function instead. Convience method to track event with optional data.
     
     - parameters:
        - encodedURLString: Encoded string that will be used for the end point for the request
        - completion: Optional callback
     */
    @available(*, deprecated, message: "No longer supported. Will be removed next version.")
    func track(encodedURLString: String,
               completion: ((_ successful: Bool, _ encodedURLString: String, _ error: NSError?)->Void)?){
        
        collect()?.send(finalStringWithParams: encodedURLString,
                        completion: { (success, info,  error) in
                            
                // Make new call but return empty responses for encodedURLString and error
                var encodedURLString = ""
                if let encodedURLStringRaw = info?[TealiumCollectKey.encodedURLString] as? String {
                    encodedURLString = encodedURLStringRaw
                }
                            
                // TODO: convert error to NSError
                completion?(success, encodedURLString, nil)
                            
        }) 
    }
    
    public func collect() -> TealiumCollect? {
        
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }
        
        return collectModule.collect
        
    }
    
}

/**
 Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
 */
class TealiumCollectModule : TealiumModule {
    
    var collect : TealiumCollect?

    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1000,
                                   build: 3,
                                   enabled: true)
    }
    
    override func enable(config:TealiumConfig) {
       
        if self.collect == nil {
            // Collect dispatch service
            var urlString : String
            if let collectURLString = config.optionalData[TealiumCollectKey.overrideCollectUrl] as? String{
                urlString = collectURLString
            } else {
                urlString = TealiumCollect.defaultBaseURLString()
            }
            self.collect = TealiumCollect(baseURL: urlString)
        }
        
        didFinishEnable(config: config)
        
    }
    
    override func disable() {
        
        self.collect = nil
        
        didFinishDisable()

    }

    override func track(_ track: TealiumTrack) {
        
        guard let collect = self.collect else {
            // TODO: Queueing system
            self.didFinishTrack(track)
            return
        }
        
        collect.dispatch(data: track.data, completion: { (success, info, error) in
            
            let newTrack = TealiumTrack(data: track.data,
                             info: info,
                       completion: track.completion)
            
            // Notify call specific callback
            track.completion?(success, info, error)
            
            // Let the modules manager know we had a failure.
            if success == false {
                var localError = error
                if localError == nil { localError = TealiumCollectError.unknownIssueWithSend }
                self.didFailToTrack(newTrack, error: localError!)
                return
            }
            
            self.didFinishTrack(newTrack)

        })
        
        
        // Completion handed off to collect dispatch service - forward track to any subsequent modules for any remaining processing.
        
    }

}
