//
//  TealiumDelegateModule.swift
//
//  Created by Jason Koo on 2/12/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

public enum TealiumDelegateKey {
    static let moduleName = "delegate"
}

public enum TealiumDelegateError : Error {
    case suppressedByShouldTrackDelegate
}

public protocol TealiumDelegate : class {
    func tealiumShouldTrack(data: [String:Any]) -> Bool
    func tealiumTrackCompleted(success:Bool, info:[String:Any]?, error:Error?)
}

extension Tealium {
    
    public func delegates() -> TealiumDelegates? {
        
        guard let module = modulesManager.getModule(forName: TealiumDelegateKey.moduleName) as? TealiumDelegateModule else {
            return nil
        }
        
        return module.delegates
        
    }
    
}

class TealiumDelegateModule : TealiumModule {
    
    var delegates : TealiumDelegates?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDelegateKey.moduleName,
                                   priority: 900,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        delegates = TealiumDelegates()
        self.didFinishEnable(config: config)
        
    }
    
    override func track(_ track: TealiumTrack) {
        
        if delegates?.invokeShouldTrack(data: track.data) == false {
            // Suppress the event from further processing
            track.completion?(false, nil, TealiumDelegateError.suppressedByShouldTrackDelegate)
            return
        }
        self.didFinishTrack(track)
        
    }
    
    override func handleReport(fromModule: TealiumModule, process: TealiumProcess) {
        
        guard let modulesManager = self.delegate as? TealiumModulesManager else {
            self.didFinishReport(fromModule: fromModule, process: process)
            return
        }
        if fromModule == modulesManager.modules.last &&
            process.type == .track  {
            
            // Report to delegates that track was completed
            delegates?.invokeTrackCompleted(forTrackProcess: process)
            
        }
        self.didFinishReport(fromModule: fromModule, process: process)
        
    }
    
    override func disable() {
        
        delegates?.removeAll()
        delegates = nil
        self.didFinishDisable()
        
    }
    
}

public class TealiumDelegates {
    
    // Unable to limit the weak array to just classes conforming to the
    //  TealiumDelegate protocol.  So the add & remove functions will
    //  do the type safety checking.
    private var weakDelegates = [Weak<AnyObject>]()

    
    /// Add a weak pointer to a class conforming to the TealiumDelegate protocol.
    ///
    /// - Parameter delegate: Class conforming to the TealiumDelegate protocols.
    public func add(delegate: TealiumDelegate) {
        
        weakDelegates.append(Weak(value: delegate))
        
    }
    
    /// Remove the weaker pointer reference to a given class from the multicast
    ///   delegates handler.
    ///
    /// - Parameter delegate: Class conforming to the TealiumDelegate protocols.
    public func remove(delegate: TealiumDelegate) {
        
        for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
            // If we have a match, remove the delegate from our array
            if delegateInArray.value === delegate {
                weakDelegates.remove(at: index)
            }
        }
        
    }
    
    
    /// Remove all weak pointer references to classes conforming to the TealiumDelegate
    ///   protocols from the multicast delgate handler.
    public func removeAll() {
        weakDelegates.removeAll()
    }
    
    /// Query all delegates if the data should be tracked or suppressed.
    ///
    /// - Parameter data: Data payload to inspect
    /// - Returns: True if all delegates approve
    public func invokeShouldTrack(data: [String:Any])-> Bool {
        
        for (_, delegateInArray) in weakDelegates.enumerated().reversed() {
            guard let delegate = delegateInArray.value as? TealiumDelegate else {
                // Should never happen
                continue
            }
            if delegate.tealiumShouldTrack(data: data) == false {
                
                return false
            }
        }
        
        return true
    }
    
    /// Inform all delegates that a track call has completed.
    ///
    /// - Parameter forTrackProcess: TealiumProcess that was completed
    public func invokeTrackCompleted(forTrackProcess: TealiumProcess) {
        
        for (_, delegateInArray) in weakDelegates.enumerated().reversed() {

            guard let delegate = delegateInArray.value as? TealiumDelegate else {
                // Should never happen
                continue
            }
            delegate.tealiumTrackCompleted(success: forTrackProcess.successful, info: forTrackProcess.track?.info, error: forTrackProcess.error)
            
        }
        
    }
}

// Convenience += and -= operators for adding/removing delegates
public func += <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.add(delegate:right)
}

public func -= <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.remove(delegate:right)
}

// Permits weak pointer collections
// Example Collection setup: var playerViewPointers = [String:Weak<PlayerView>]()
// Example Set: playerViewPointers[someKey] = Weak(value: playerView)
// Example Get: let x = playerViewPointers[user.uniqueId]?.value
class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}
