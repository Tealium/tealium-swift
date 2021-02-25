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

public class AutotrackingModule: Collector {

    public let id: String = TealiumAutotrackingKey.moduleName
    public var data: [String: Any]?
    weak var delegate: ModuleDelegate?
    public var config: TealiumConfig
    var context: TealiumContext
    weak var autotrackingDelegate: AutoTrackingDelegate?
    var lastEvent: String?
    var token: NotificationToken?
    
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
        self.context = context
        self.config = context.config
        enableNotifications()
        self.autotrackingDelegate = config.autoTrackingCollectorDelegate
        completion((.success(true), nil))
    }

    func enableNotifications() {
        let viewName = Notification.Name(rawValue: TealiumAutotrackingKey.viewNotificationName)
        let token = NotificationCenter.default.addObserver(forName: viewName, object: nil, queue: nil) { [weak self] notification in
            guard let viewName = notification.userInfo?["view_name"] as? String, let self = self else {
                return
            }
            self.requestViewTrack(viewName: viewName)
        }
        self.token = NotificationToken(token: token)
    }

    func requestViewTrack(viewName: String) {
        guard lastEvent != viewName else {
            let logRequest = TealiumLogRequest(message: "Suppressing duplicate screen view: \(viewName)")
            context.log(logRequest)
            return
        }

        var data: [String: Any] = [TealiumKey.event: viewName,
                                   TealiumAutotrackingKey.autotracked: "true"]
        
        if let autotrackingDelegate = self.autotrackingDelegate {
            data += autotrackingDelegate.onCollectScreenView(screenName: viewName)
        }

        let view = TealiumView(viewName, dataLayer: data)
        
        context.track(view)
        self.lastEvent = viewName
    }

}
