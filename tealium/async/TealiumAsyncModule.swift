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
}

extension Tealium {
    
    convenience init(config: TealiumConfig, completion:@escaping (()->Void)){
        
        config.optionalData[TealiumAsyncKey.completion] = completion
        
        self.init(config: config)
        
    }
}

/// Module to send all calls to a Tealium only background thread
class TealiumAsyncModule : TealiumModule {
    
    var _dispatchQueue : DispatchQueue?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAsyncKey.moduleName,
                                   priority: 200,
                                   build: 2,
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
    
    override func handleReport(fromModule: TealiumModule, process: TealiumProcess) {
        
        dispatchQueue().async {
            
            self.didFinishReport(fromModule: fromModule, process: process)
            
            if let completion = self.completionInit(fromModule: fromModule, process: process){
                completion()
            }
            
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
    
    
    /// Return an init completion block from the last module, if it exists.
    ///
    /// - Parameters:
    ///   - fromModule: The module to check.
    ///   - process: The process to inspect.
    /// - Returns: Optional init completion block.
    internal func completionInit(fromModule: TealiumModule, process: TealiumProcess) -> (()->Void)? {
        
        if process.type != .enable {
            return nil
        }
        
        guard let moduleManager = self.delegate as? TealiumModulesManager else {
            return nil
        }
        
        if fromModule != moduleManager.modules.last {
            return nil
        }
        
        guard let completion = moduleManager.config.optionalData[TealiumAsyncKey.completion] as? (()->Void) else {
            return nil
        }
        
        return completion
        
    }
    
}
