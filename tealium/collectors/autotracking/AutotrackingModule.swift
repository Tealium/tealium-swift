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

    @ToAnyObservable<TealiumBufferedSubject>(TealiumBufferedSubject(bufferSize: 10))
    static var onAutoTrackView: TealiumObservable<String>

    public let id: String = TealiumAutotrackingKey.moduleName
    public var data: [String: Any]?
    weak var delegate: ModuleDelegate?
    public var config: TealiumConfig
    var context: TealiumContext
    weak var autotrackingDelegate: AutoTrackingDelegate?
    var lastEvent: String?
    var disposeBag = TealiumDisposeBag()
    // Lowercased list of blocked view names
    var blockList: [String]?
    let blockListBundle: Bundle

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject())
    private var onReady: TealiumObservable<Void>

    init(context: TealiumContext,
         delegate: ModuleDelegate?,
         diskStorage: TealiumDiskStorageProtocol?,
         blockListBundle: Bundle,
         completion: ModuleCompletion) {
        self.delegate = delegate
        self.context = context
        self.config = context.config
        self.blockListBundle = blockListBundle
        loadBlocklist()
        self.autotrackingDelegate = config.autoTrackingCollectorDelegate
        TealiumQueues.secureMainThreadExecution {
            AutotrackingModule.onAutoTrackView.subscribe { [weak self] viewName in
                self?.requestViewTrack(viewName: viewName)
            }.toDisposeBag(self.disposeBag)
        }
        completion((.success(true), nil))
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public convenience init(context: TealiumContext,
                                     delegate: ModuleDelegate?,
                                     diskStorage: TealiumDiskStorageProtocol?,
                                     completion: ModuleCompletion) {
        self.init(context: context,
                  delegate: delegate,
                  diskStorage: diskStorage,
                  blockListBundle: Bundle.main,
                  completion: completion)
            }

    func requestViewTrack(viewName: String) {
        guard lastEvent != viewName else {
            let logRequest = TealiumLogRequest(message: "Suppressing duplicate screen view: \(viewName)")
            context.log(logRequest)
            return
        }
        onReady.subscribeOnce { [weak self] in
            guard let self = self else {
                return
            }
            guard self.shouldBlock(viewName) == false else {
                return
            }

            var data: [String: Any] = [TealiumDataKey.event: viewName,
                                       TealiumDataKey.autotracked: "true"]

            if let autotrackingDelegate = self.autotrackingDelegate {
                data += autotrackingDelegate.onCollectScreenView(screenName: viewName)
            }

            let view = TealiumView(viewName, dataLayer: data)

            self.context.track(view)
            self.lastEvent = viewName
        }
    }

    func shouldBlock(_ viewName: String) -> Bool {
        guard let blockList = blockList else {
            return false
        }
        let lowerCasedView = viewName.lowercased()
        return blockList.contains { blockKey in
            return lowerCasedView.contains(blockKey)
        }
    }

    func loadBlocklist() {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            do {
                var list: [String]?
                if let file = self.config.autoTrackingBlocklistFilename,
                   let blockList: [String] = try JSONLoader.fromFile(file, bundle: self.blockListBundle, logger: nil) {
                    list = blockList
                } else if let url = self.config.autoTrackingBlocklistURL,
                          let blockList: [String] = try JSONLoader.fromURL(url: url, logger: nil) {
                    list = blockList
                }
                self.blockList = list?.map { $0.lowercased() }
            } catch let error {
                if let error = error as? LocalizedError {
                    let logRequest = TealiumLogRequest(title: "Auto Tracking",
                                                       message: "BlockList could not be loaded. Error: \(error.localizedDescription)",
                                                       info: nil, logLevel: .error, category: .general)
                    self.context.log(logRequest)
                }
            }
            TealiumQueues.mainQueue.async { [weak self] in
                self?._onReady.publish()
            }
        }
    }

    static func autoTrackView(viewName: String) {
        _onAutoTrackView.publish(viewName)
    }

}
