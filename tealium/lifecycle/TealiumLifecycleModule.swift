//
//  TealiumLifecycleModule.swift
//
//  Created by Jason Koo on 1/10/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

#if TEST
#else
    #if os(OSX)
    #else
        import UIKit
    #endif
#endif

extension Tealium {
    
    public func lifecycle() -> TealiumLifecycleModule? {
        
        guard let module = modulesManager.getModule(forName: TealiumLifecycleModuleKey.moduleName) as? TealiumLifecycleModule else {
            return nil
        }
        return module
        
    }
    
}

enum TealiumLifecycleModuleKey {
    static let moduleName = "lifecycle"
    static let queueName = "com.tealium.lifecycle"
}

enum TealiumLifecycleModuleError : Error {
    case unableToSaveToDisk
}

public class TealiumLifecycleModule : TealiumModule {
    
    fileprivate var _dispatchQueue : DispatchQueue?
    var areListenersActive = false
    var enabledPrior = false    // To differentiate between new launches and re-enables.
    var lifecycle : TealiumLifecycle?
    var uniqueId : String = ""
    var lastProcess : TealiumLifecycleType?
    
    // MARK:
    // MARK: MODULE OVERRIDES
    
    override public func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumLifecycleModuleKey.moduleName,
                                   priority: 175,
                                   build: 2,
                                   enabled: true)
    }
    
    override public func enable(config: TealiumConfig) {
        
        if areListenersActive == false {
            addListeners()
        }
    
        uniqueId = "\(config.account).\(config.profile).\(config.environment)"
        lifecycle = savedOrNewLifeycle(uniqueId: uniqueId)
        
        let save = TealiumLifecyclePersistentData.save(lifecycle!, usingUniqueId: uniqueId)
        if save.success == false {
            self.didFailToEnable(config: config, error: save.error!)
            return
        }
        self.didFinishEnable(config: config)
        
    }
    
    override public func disable() {
        
        lifecycle = nil
        _dispatchQueue = nil
        self.didFinishDisable()
            
    }
    
    override public func track(_ track: TealiumTrack) {
        
        // Lifecycle ready?
        guard let lifecycle = self.lifecycle else {
            self.didFinishTrack(track)
            return
        }
        
        
        var newData = lifecycle.newTrack(atDate: Date())
        newData += track.data
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        self.didFinishTrack(newTrack)
        
    }
    
    override public func handleReport(fromModule: TealiumModule, process: TealiumProcess) {
        
        if let modulesManager = self.delegate as? TealiumModulesManager,
            modulesManager.allModulesReady(),
            modulesManager.modules.last == fromModule,
            process.type == .enable {
            
            launchDetected()
        }
        self.didFinishReport(fromModule: fromModule, process: process)
        
    }
    
    // MARK:
    // MARK: PUBLIC
    
    func launchDetected(){
        processDetected(type: .launch)
    }
    
    @objc func sleepDetected() {
        processDetected(type: .sleep)
    }
    
    @objc func wakeDetected() {
        processDetected(type: .wake)
    }
    
    // MARK:
    // MARK: INTERNAL
    
    internal func addListeners() {
        
        // Pretty gross
        #if TEST
        #else
            #if os(watchOS)
            #else
                #if os(OSX)
                #else
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(wakeDetected),
                                                           name: NSNotification.Name.UIApplicationWillEnterForeground,
                                                           object: nil)
                    
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(sleepDetected),
                                                           name: NSNotification.Name.UIApplicationDidEnterBackground,
                                                           object: nil)
                    
                #endif
            #endif
        #endif
        areListenersActive = true
        
    }
    
    internal func dispatchQueue() -> DispatchQueue {
        
        if _dispatchQueue == nil {
            _dispatchQueue = DispatchQueue(label: TealiumLifecycleModuleKey.queueName)
        }
        return _dispatchQueue!
        
    }
    
    internal func processDetected(type: TealiumLifecycleType) {
        
        if processAcceptable(type: type) == false {
            return
        }
        
        lastProcess = type
        dispatchQueue().async {
            self.process(type: type)
        }
        
    }
    
    internal func process(type: TealiumLifecycleType) {
        
        // If lifecycle has been nil'd out - module not ready or has been disabled
        guard let lifecycle = self.lifecycle else { return }
        
        // Setup data to be used in switch statement
        let date = Date()
        var data : [String:Any]
        
        // Update internal model and retrieve data for a track call
        switch type {
        case .launch:
            if enabledPrior == true { return }
            enabledPrior = true
            data = lifecycle.newLaunch(atDate: date,
                                       overrideSession: nil)
        case .sleep:
            data = lifecycle.newSleep(atDate: date)
        case .wake:
            data = lifecycle.newWake(atDate: date,
                                     overrideSession: nil)
        }
        
        // Save now in case we crash later
        save()
        
        // Make the track request to the modulesManager
        requestTrack(data: data)
        
    }
    
    
    /// Prevent manual spanning of repeated lifecycle calls to system.
    ///
    /// - Parameters:
    ///   - type: Lifecycle event type
    ///   - lastProcess: Last lifecycle event type recorded
    /// - Returns: Bool is process should be allowed to continue
    internal func processAcceptable(type: TealiumLifecycleType) -> Bool {
        
        switch type {
        case .launch:
            // Can only occur once per app lifecycle
            if enabledPrior == true {
                return false
            }
            if let _ = lastProcess {
                // Should never have more than 1 launch event per app lifecycle run
                return false
            }
        case .sleep:
            guard let lastProcess = lastProcess else {
                // Should not be possible
                return false
            }
            if lastProcess != .wake && lastProcess != .launch {
                return false
            }
        case .wake:
            guard let lastProcess = lastProcess else {
                // Should not be possible
                return false
            }
            if lastProcess != .sleep {
                return false
            }
        }
        return true
        
    }
    
    internal func requestTrack(data: [String:Any]) {
        
        guard let title = data[TealiumLifecycleKey.type] as? String else {
            // Should not happen
            return
        }
        
        // Conforming to universally available Tealium data variables
        let trackData = Tealium.trackDataFor(type: .activity,
                                             title: title,
                                             optionalData: data)
        let track = TealiumTrack(data: trackData,
                                 info: [:],
                                 completion: nil)
        let process = TealiumProcess(type: .track,
                                     successful: true,
                                     track: track,
                                     error: nil)
        self.delegate?.tealiumModuleRequests(module: self, process: process)
        
    }
    
    internal func save() {
        
        // Error handling?
        guard let lifecycle = self.lifecycle else {
            return
        }
        let _ = TealiumLifecyclePersistentData.save(lifecycle, usingUniqueId: uniqueId)
        
    }
    
    internal func savedOrNewLifeycle(uniqueId: String) -> TealiumLifecycle {
        
        // Attempt to load first
        if let loadedLifecycle = TealiumLifecyclePersistentData.load(uniqueId: uniqueId) {
            return loadedLifecycle
        }
        return TealiumLifecycle()
        
    }
    
    deinit {
        
        if areListenersActive == true {
            #if os(OSX)
            #else
                NotificationCenter.default.removeObserver(self)
            #endif
        }
        
    }
    
}


