//
//  TealiumAutotrackingModule.swift
//
//  Created by Jason Koo on 12/21/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

#if TEST
    import Foundation
#else
    import UIKit
#endif

enum TealiumAutotrackingKey {
    static let moduleName = "autotracking"
    static let eventNotificationName = "com.tealium.autotracking.event"
    static let viewNotificationName = "com.tealium.autotracking.view"
    static let autotracked = "autotracked"
}

extension Tealium {
    
    public func autotracking() -> TealiumAutotracking? {
        
        guard let module = modulesManager.getModule(forName: TealiumAutotrackingKey.moduleName) as? TealiumAutotrackingModule else {
            return nil
        }
        
        return module.autotracking
        
    }
    
}

public protocol TealiumAutotrackingDelegate : class {
    
    func tealiumAutotrackShouldTrack(data: [String:Any]) -> Bool
    func tealiumAutotrackCompleted(success:Bool, info:[String:Any]?, error:Error?)
    
}

var tealiumAssociatedObjectHandle : UInt8 = 0

public class TealiumAutotracking {
    
    weak var delegate : TealiumAutotrackingDelegate?
    
    /// Add custom data to an object, to be included with an autotracked event.
    ///
    /// - Parameters:
    ///   - data: [String:Any] dictionary. Values should be String or [String]
    ///   - toObject: Object to add data for.
    class func addCustom(data: [String:Any], toObject:NSObject) {
        
        // Overwrites existing?
        objc_setAssociatedObject(toObject,
                                 &tealiumAssociatedObjectHandle,
                                 data,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
    
    /// Retrieve any custom data previously associated with object.
    ///
    /// - Parameter forObject: NSObject to retrieve data for.
    /// - Returns: Optional [String:Any] dictionary
    class func customData(forObject:NSObject) -> [String:Any]? {
        
        guard let associatedData = objc_getAssociatedObject(forObject, &tealiumAssociatedObjectHandle) as? [String:Any] else {
            return nil
        }
        
        return associatedData
        
    }
    
    /// Remove all custom Tealium data associated to an object.
    ///
    /// - Parameter fromObject: NSObject to disassociate data from.
    class func removeCustomData(fromObject:NSObject) {
        
        objc_setAssociatedObject(fromObject,
                                 &tealiumAssociatedObjectHandle,
                                 nil,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
    
}

class TealiumAutotrackingModule : TealiumModule {
    
    var notificationsEnabled = false
    let autotracking = TealiumAutotracking()
    
    // MARK:
    // MARK: SUBCLASS OVERIDES
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAutotrackingKey.moduleName,
                                   priority: 300,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        let eventName = NSNotification.Name.init(TealiumAutotrackingKey.eventNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestEventTrack(sender:)), name: eventName, object: nil)

        let viewName = NSNotification.Name.init(TealiumAutotrackingKey.viewNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestViewTrack(sender:)), name: viewName, object: nil)
        
        notificationsEnabled = true
        self.didFinishEnable(config: config)
        
    }
    
    override func disable() {
        
        if notificationsEnabled == true {
            NotificationCenter.default.removeObserver(self)
            notificationsEnabled = false
        }
        
        self.didFinishDisable()
            
    }

    // MARK:
    // MARK: INTERNAL
    
    @objc internal func requestEventTrack(sender: Notification) {
        
        if notificationsEnabled == false {
            return
        }
    
        guard let object = sender.object as? NSObject else {
            return
        }
        
        let title = String(describing: type(of: object))
        
        var data: [String : Any] = [TealiumKey.event: title ,
                                    TealiumKey.eventName: title ,
                                    TealiumKey.eventType: TealiumTrackType.activity.description(),
                                    TealiumAutotrackingKey.autotracked : "true"]
        
        if let customData = TealiumAutotracking.customData(forObject: object) {
            data += customData
        }
        
        requestTrack(data: data)

    }
    
    @objc internal func requestViewTrack(sender: Notification) {
        
        if notificationsEnabled == false {
            return
        }
        
        #if TEST
        #else
        guard let viewController = sender.object as? UIViewController else {
            return
        }
        
        let title = viewController.title ?? String(describing: type(of: viewController))
        var data: [String : Any] = [TealiumKey.event: title ,
                                    TealiumKey.eventName: title ,
                                    TealiumKey.eventType: TealiumTrackType.view.description(),
                                    TealiumAutotrackingKey.autotracked : "true",
                                    ]
            
        if let customData = TealiumAutotracking.customData(forObject: viewController) {
            data += customData
        }

        requestTrack(data: data)
        #endif
        
    }
    
    
    /// Make track requests to core library - called from the event & viewDidAppear listeners
    ///
    /// - Parameter data: [String:Any] additional variable data.
    internal func requestTrack(data: [String:Any]) {
        
        if autotracking.delegate?.tealiumAutotrackShouldTrack(data: data) == false {
            return
        }
        
        let completion : tealiumTrackCompletion = {(success, info, error) in
            self.autotracking.delegate?.tealiumAutotrackCompleted(success:success, info:info, error:error)
        }
        
        let track = TealiumTrack(data: data,
                                 info: [:],
                                 completion: completion)
        
        let process = TealiumProcess(type: .track,
                                     successful: true,
                                     track: track,
                                     error: nil)
        
        self.delegate?.tealiumModuleRequests(module: self, process: process)
        
    }
    
    deinit {
        
        if notificationsEnabled == true {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
}
