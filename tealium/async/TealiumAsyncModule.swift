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
    static let completion = "async_init_completion"
    static let disableCompletion = "async_disable_completion"
}

/// Module to send all calls to a Tealium only background thread
class TealiumAsyncModule : TealiumModule {
    
    var _dispatchQueue : DispatchQueue?
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAsyncKey.moduleName,
                                   priority: 200,
                                   build: 4,
                                   enabled: true)
    }
    
    override func handle(_ request: TealiumRequest) {
        
        switch request {
        case is TealiumEnableRequest:
            enable(request as! TealiumEnableRequest)
        case is TealiumDisableRequest:
            disable(request as! TealiumDisableRequest)
        default:
            // Send everything else to the background thread
            dispatchQueue().async {
                self.didFinish(request)
            }
        }
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        
        dispatchQueue().async {
        
            self.didFinish(request)

        }
        
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        isEnabled = false
        
        dispatchQueue().async {
            
            self.didFinish(request)
            
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
            if #available(OSX 10.10, *) {
                _dispatchQueue = DispatchQueue.global(qos: .background)
            } else {
                // Fallback on earlier versions
                _dispatchQueue = DispatchQueue.global(priority: .background)
            }
        }
        
        return _dispatchQueue!
        
    }
    
}
