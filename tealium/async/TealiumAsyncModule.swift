//
//  TealiumAsyncModule.swift
//
//  Created by Jason Koo on 12/13/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumAsyncKey {
    static let moduleName = "async"
    static let queueName = "com.tealium.background"
}

/// Module to send all calls to a Tealium only background thread
class TealiumAsyncModule : TealiumModule {
    
    var _dispatchQueue : DispatchQueue?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAsyncKey.moduleName,
                                   priority: 200,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        dispatchQueue().async {
        
            self.didFinishEnable(config: config)

        }
        
    }
    
    override func disable() {
        
        dispatchQueue().async {

            self.didFinishDisable()
            
        }
    }
    
    override func track(_ track: TealiumTrack) {
    
        dispatchQueue().async {

            self.didFinishTrack(track)
        
        }
    }
    
    
    /// Override the default Tealium background queue.
    ///
    /// - Parameter queue: Queue to set all Tealium processing to.
    func setDispatchQueue(queue: DispatchQueue) {
        
        _dispatchQueue = queue
        
    }
    
    func dispatchQueue() -> DispatchQueue {
        
        if _dispatchQueue == nil {
            _dispatchQueue = DispatchQueue(label: TealiumAsyncKey.queueName)
        }
        
        return _dispatchQueue!
        
    }
    
}
