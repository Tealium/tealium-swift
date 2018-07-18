//
//  TealiumAutotrackingModule.swift
//
//  Created by Jason Koo on 12/21/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

#if TEST
    import Foundation
#else
    #if os(macOS)
    #else
        import UIKit
    #endif
#endif

enum TealiumAutotrackingKey {
    static let moduleName = "autotracking"
    static let eventNotificationName = "com.tealium.autotracking.event"
    static let viewNotificationName = "com.tealium.autotracking.view"
    static let autotracked = "autotracked"
}

public extension Tealium {

    func autotracking() -> TealiumAutotracking? {

        guard let module = modulesManager.getModule(forName: TealiumAutotrackingKey.moduleName) as? TealiumAutotrackingModule else {
            return nil
        }

        return module.autotracking
    }

}

var tealiumAssociatedObjectHandle: UInt8 = 0

public class TealiumAutotracking {

    /// Add custom data to an object, to be included with an autotracked event.
    ///
    /// - Parameters:
    ///   - data: [String:Any] dictionary. Values should be String or [String]
    ///   - toObject: Object to add data for.
    public class func addCustom(data: [String: Any], toObject: NSObject) {
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
    public class func customData(forObject: NSObject) -> [String: Any]? {
        guard let associatedData = objc_getAssociatedObject(forObject, &tealiumAssociatedObjectHandle) as? [String: Any] else {
            return nil
        }

        return associatedData
    }

    /// Remove all custom Tealium data associated to an object.
    ///
    /// - Parameter fromObject: NSObject to disassociate data from.
    public class func removeCustomData(fromObject: NSObject) {
        objc_setAssociatedObject(fromObject,
                                 &tealiumAssociatedObjectHandle,
                                 nil,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Instance level addCustom data function - convenience for framework APIs.
    ///
    /// - Parameters:
    ///   - data: [String:Any] dictionary. Values should be String or [String]
    ///   - toObject: Object to add data for.
    public func addCustom(data: [String: Any],
                          toObject: NSObject) {
        TealiumAutotracking.addCustom(data: data,
                                      toObject: toObject)
    }

    /// Instance level customData function - convenience for framework APIs.
    ///
    /// - Parameter forObject: NSObject to retrieve data for.
    /// - Returns: Optional [String:Any] dictionary
    public func customData(forObject: NSObject) -> [String: Any]? {
        return TealiumAutotracking.customData(forObject: forObject)
    }

    /// Instance level removeCustomData function - convenience for framework APIs.
    ///
    /// - Parameter fromObject: NSObject to disassociate data from.
    public func removeCustomData(fromObject: NSObject) {
        TealiumAutotracking.removeCustomData(fromObject: fromObject)
    }
}

class TealiumAutotrackingModule: TealiumModule {

    var notificationsEnabled = false
    let autotracking = TealiumAutotracking()

    // MARK: 
    // MARK: SUBCLASS OVERIDES

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAutotrackingKey.moduleName,
                                   priority: 300,
                                   build: 4,
                                   enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true

        let eventName = NSNotification.Name(TealiumAutotrackingKey.eventNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestEventTrack(sender:)), name: eventName, object: nil)

        let viewName = NSNotification.Name(TealiumAutotrackingKey.viewNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestViewTrack(sender:)), name: viewName, object: nil)

        notificationsEnabled = true
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false

        if notificationsEnabled == true {
            // swiftlint:disable notification_center_detachment
            NotificationCenter.default.removeObserver(self)
            // swiftlint:enable notification_center_detachment
            notificationsEnabled = false
        }

        didFinish(request)
    }

    // MARK: 
    // MARK: INTERNAL

    @objc
    func requestEventTrack(sender: Notification) {

        if notificationsEnabled == false {
            return
        }

        guard let object = sender.object as? NSObject else {
            return
        }

        let title = String(describing: type(of: object))

        var data: [String: Any] = [TealiumKey.event: title ,
                                    TealiumAutotrackingKey.autotracked: "true"]

        if let customData = TealiumAutotracking.customData(forObject: object) {
            data += customData
        }

        requestTrack(data: data)
    }

    @objc
    func requestViewTrack(sender: Notification) {
        if notificationsEnabled == false {
            return
        }

        #if TEST
        #else
        guard let viewController = sender.object as? UIViewController else {
            return
        }

        let title = viewController.title ?? String(describing: type(of: viewController))
        var data: [String: Any] = [TealiumKey.event: title ,
                                    TealiumAutotrackingKey.autotracked: "true"
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
    func requestTrack(data: [String: Any]) {
        let track = TealiumTrackRequest(data: data,
                                        completion: nil)

        self.delegate?.tealiumModuleRequests(module: self, process: track)
    }

    deinit {
        if notificationsEnabled == true {
            NotificationCenter.default.removeObserver(self)
        }
    }

}
