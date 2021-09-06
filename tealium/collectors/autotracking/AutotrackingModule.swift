//
//  AutotrackingModule.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
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
    var disposeBag = TealiumDisposeBag()
    var blockList: [String]?
    
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
        loadBlocklist()
        self.autotrackingDelegate = config.autoTrackingCollectorDelegate
        
        TealiumQueues.secureMainThreadExecution {
            TealiumInstanceManager.shared.onAutoTrackView.subscribe { [weak self] viewName in
                self?.requestViewTrack(viewName: viewName)
            }.toDisposeBag(self.disposeBag)
        }
        completion((.success(true), nil))
    }

    func requestViewTrack(viewName: String) {
        guard lastEvent != viewName else {
            let logRequest = TealiumLogRequest(message: "Suppressing duplicate screen view: \(viewName)")
            context.log(logRequest)
            return
        }
        
        guard shouldBlock(viewName) == false else {
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
    
    func shouldBlock(_ eventName: String) -> Bool {
        guard let blockList = blockList else {
            return false
        }
        return blockList.contains(eventName)
    }

    func loadBlocklist() {
        do {
            if let file = config.autoTrackingBlocklistFilename,
               let blockList: [String]? = try JSONLoader.fromFile(file, bundle: .main, logger: nil) {
                self.blockList = blockList
            } else if let url = config.autoTrackingBlocklistURL,
                      let blockList: [String]? = try JSONLoader.fromURL(url: url, logger: nil) {
                self.blockList = blockList
            } else {
                self.blockList = nil
            }
        } catch let error {
            if let error = error as? LocalizedError {
                let logRequest = TealiumLogRequest(title: "Auto Tracking", message: "BlockList could not be loaded. Error: \(error.localizedDescription)", info: nil, logLevel: .error, category: .general)
                context.log(logRequest)
            }
            
        }
        
    }
    
}
