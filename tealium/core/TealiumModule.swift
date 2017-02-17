//
//  TealiumModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Build 2

import Foundation

public protocol TealiumModuleDelegate : class {
    
    /// Called by modules after they've completed a requested command or encountered an error.
    ///
    /// - Parameters:
    ///   - module: Module that finished processing.
    ///   - process: The TealiumProcess completed.
    func tealiumModuleFinished(module: TealiumModule,
                               process: TealiumProcess)
    
    /// Called by module after finished processing a request originating from
    ///   a request from another module.
    ///
    /// - Parameters:
    ///   - fromOriginatingModule: Original sender.
    ///   - module: Module just finished processing.
    ///   - process: TealiumModuleProcessType completed.
    ///   - track: Possible related track.
    func tealiumModuleFinishedReport(fromModule: TealiumModule,
                                     module: TealiumModule,
                                     process: TealiumProcess)
    
    /// Called by module requesting an library operation.
    ///
    /// - Parameters:
    ///   - module: Module making request.
    ///   - process: TealiumModuleProcessType requested.
    ///   - track: Optional track.
    func tealiumModuleRequests(module: TealiumModule,
                               process: TealiumProcess)
}

/**
    Base class for all Tealium feature modules.
 */
open class TealiumModule {
    
    weak var delegate : TealiumModuleDelegate?
    var isEnabled : Bool = false
    
    /// Constructor.
    ///
    /// - Parameter delegate: Delegate for module, usually the ModulesManager.
    required public init(delegate: TealiumModuleDelegate?){
        self.delegate = delegate
    }
    
    // MARK:
    // MARK: OVERRIDABLE FUNCTIONS
    open func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: "default",
                                   priority: 0,
                                   build: 0,
                                   enabled: false)
    }
    
    /// Should only be called by the ModulesManager.
    ///
    /// - Parameter config: TealiumConfig used to initialize this instance of Tealium.
    open func update(config: TealiumConfig) {
        
        if moduleConfig().enabled == false {
            disable()
            return
        }
        
        enable(config: config)
    }
    
    // MARK:
    // MARK: PUBLIC OVERRIDES
    
    // These methods are meant to be overwritten by module subclasses. DidFinish
    // methods should be called when complete unless module is specifically
    // designed to prevent handling of chainable calls by modules further
    // down the chain of responsibility.
    
    /**
     Start the module.
     
     - parameters:
        - config: The TealiumConfig object used for the instance this module is associated with.
     */
    open func enable(config: TealiumConfig) {
        
        didFinishEnable(config: config)
        
    }
    
    /**
     Stop the module from futher running.
     */
    open func disable() {
        
        didFinishDisable()

    }

    /// Handle track requests - usually adding or editing data,
    /// adding info, or dispatching formatted data.
    ///
    /// - Parameter track: The TealiumTrack object to process.
    open func track(_ track: TealiumTrack) {
        
        didFinishTrack(track)
    }
    
    /// Handle enable completion by another module (ie logging).
    ///
    /// - Parameter fromModule: Module originally reporting enable.
    /// - Parameter process: Related TealiumProcess
    open func handleReport(fromModule: TealiumModule,
                      process: TealiumProcess) {
        
        didFinishReport(fromModule: fromModule,
                        process: process)
    }
    
    // MARK:
    // MARK: PACKAGE PUBLIC - No need to override
    
    /// Convenience method for auto routing processing requests by modulesManager.
    ///
    /// - Parameters:
    ///   - type: TealiumModuleProcessType of call.
    ///   - config: Possible TealiumConfig used to init this instance of Tealium.
    ///   - track: Possible track related to request.
    open func auto(_ process: TealiumProcess,
              config: TealiumConfig){
        
        switch process.type {
        case .enable:
            self.enable(config: config)
        case .disable:
            self.disable()
        case .track:
            guard let track = process.track else {
                self.didFailToTrack(process.track,
                                    error: TealiumModuleError.missingTrackData)
                return
            }
            self.track(track)
        }
        
    }
    
    // MARK:
    // MARK: SUBCLASS CONVENIENCE METHODS
    
    open func didFinishEnable(config:TealiumConfig) {
        
        isEnabled = true
        let process = TealiumProcess(type: .enable,
                                     successful: true,
                                     track: nil,
                                     error: nil)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
        
    }
    
    open func didFailToEnable(config:TealiumConfig,
                         error: Error)
    {
        let process = TealiumProcess(type: .enable,
                                     successful: false,
                                     track: nil,
                                     error: error)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
    }
    
    open func didFinishDisable() {
        let process = TealiumProcess(type: .disable,
                                     successful: true,
                                     track: nil,
                                     error: nil)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
    }
    
    open func didFailToDisable(error:Error){
        
        let process = TealiumProcess(type: .disable,
                                     successful: false,
                                     track: nil,
                                     error: error)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
    }
    
    open func didFinishTrack(_ track: TealiumTrack){
        
        let process = TealiumProcess(type: .track,
                                     successful: true,
                                     track: track,
                                     error: nil)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
        
    }
    
    open func didFailToTrack(_ track: TealiumTrack?,
                        error: Error){
        
        let process = TealiumProcess(type: .track,
                                     successful: false,
                                     track: track,
                                     error: error)
        delegate?.tealiumModuleFinished(module: self,
                                        process: process)
        
    }
    
    open func didFinishReport(fromModule: TealiumModule,
                         process: TealiumProcess){
        
        delegate?.tealiumModuleFinishedReport(fromModule: fromModule,
                                              module: self,
                                              process: process)
    }

    
}

extension TealiumModule : CustomStringConvertible {
    public var description : String {
        return "\(moduleConfig().name).module"
    }
}

extension TealiumModule : Equatable {
    
    public static func == (lhs: TealiumModule, rhs: TealiumModule ) -> Bool {
        return lhs.moduleConfig() == rhs.moduleConfig()
    }
    
}
