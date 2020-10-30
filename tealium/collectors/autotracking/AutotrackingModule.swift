//
//  AutotrackingModule.swift
//  tealium-swift
//
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

#if autotracking
import TealiumCore
#endif

enum TealiumAutotrackingKey {
    static let moduleName = "autotracking"
    static let eventNotificationName = "com.tealium.autotracking.event"
    static let viewNotificationName = "com.tealium.autotracking.view"
    static let autotracked = "autotracked"
}

public extension Tealium {

    var autotracking: TealiumAutotrackingManager? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == AutotrackingModule.self
        } as? AutotrackingModule)?.autotracking
    }

}

var tealiumAssociatedObjectHandle: UInt8 = 0

public class TealiumAutotrackingManager {

    /// Add custom data to an object, to be included with an autotracked event.
    ///￼
    /// - Parameter data: `[String:Any]` dictionary. Values should be String or [String]￼
    /// - Parameter toObject: `NSObject` to add data for.
    public class func addCustom(data: [String: Any], toObject: NSObject) {
        // Overwrites existing?
        objc_setAssociatedObject(toObject,
                                 &tealiumAssociatedObjectHandle,
                                 data,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    }

    /// Retrieve any custom data previously associated with object.
    ///￼
    /// - Parameter forObject: `NSObject` to retrieve data for.
    /// - Returns: `[String:Any]?` dictionary
    public class func customData(forObject: NSObject) -> [String: Any]? {
        guard let associatedData = objc_getAssociatedObject(forObject, &tealiumAssociatedObjectHandle) as? [String: Any] else {
            return nil
        }

        return associatedData
    }

    /// Remove all custom Tealium data associated to an object.
    ///￼
    /// - Parameter fromObject: `NSObject` to disassociate data from.
    public class func removeCustomData(fromObject: NSObject) {
        objc_setAssociatedObject(fromObject,
                                 &tealiumAssociatedObjectHandle,
                                 nil,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Instance level addCustom data function - convenience for framework APIs.
    ///￼
    /// - Parameter data: `[String:Any]`. Values should be `String` or `[String]￼`.
    /// - Parameter toObject: `NSObject` to add data for.
    public func addCustom(data: [String: Any],
                          toObject: NSObject) {
        TealiumAutotrackingManager.addCustom(data: data,
                                             toObject: toObject)
    }

    /// Instance level customData function - convenience for framework APIs.
    ///￼
    /// - Parameter forObject: `NSObject` to retrieve data for.
    /// - Returns: `[String:Any]?`
    public func customData(forObject: NSObject) -> [String: Any]? {
        return TealiumAutotrackingManager.customData(forObject: forObject)
    }

    /// Instance level removeCustomData function - convenience for framework APIs.
    ///￼
    /// - Parameter fromObject: NSObject to disassociate data from.
    public func removeCustomData(fromObject: NSObject) {
        TealiumAutotrackingManager.removeCustomData(fromObject: fromObject)
    }
}

public class AutotrackingModule: Collector {

    public let id: String = TealiumAutotrackingKey.moduleName
    public var data: [String: Any]?
    weak var delegate: ModuleDelegate?
    public var config: TealiumConfig

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.delegate = delegate
        self.config = context.config
        let eventName = NSNotification.Name(TealiumAutotrackingKey.eventNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestEventTrack(sender:)), name: eventName, object: nil)

        let viewName = NSNotification.Name(TealiumAutotrackingKey.viewNotificationName)
        NotificationCenter.default.addObserver(self, selector: #selector(requestViewTrack(sender:)), name: viewName, object: nil)

        notificationsEnabled = true
        completion((.success(true), nil))
    }

    var notificationsEnabled = false
    let autotracking = TealiumAutotrackingManager()

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

        if let customData = TealiumAutotrackingManager.customData(forObject: object) {
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

        if let customData = TealiumAutotrackingManager.customData(forObject: viewController) {
            data += customData
        }

        requestTrack(data: data)
        #endif
    }

    /// Make track requests to core library - called from the event & viewDidAppear listeners
    ///￼
    /// - Parameter data: `[String:Any]` additional variable data.
    func requestTrack(data: [String: Any]) {
        let track = TealiumTrackRequest(data: data)

        delegate?.requestTrack(track)
    }

    deinit {
        if notificationsEnabled == true {
            NotificationCenter.default.removeObserver(self)
            notificationsEnabled = false
        }
    }

}
