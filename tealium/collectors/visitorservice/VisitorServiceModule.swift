//
//  TealiumVisitorServiceModule.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public class VisitorServiceModule: Collector, DispatchListener {

    public let id: String = ModuleNames.visitorservice
    public var config: TealiumConfig
    public var data: [String: Any]?
    var diskStorage: TealiumDiskStorageProtocol!
    var visitorServiceManager: VisitorServiceManagerProtocol?
    private var bag = TealiumDisposeBag()
    private var lastVisitorId: String? {
        get {
            self.visitorServiceManager?.currentVisitorId
        }
        set {
            self.visitorServiceManager?.currentVisitorId = newValue
        }
    }
    /// Provided for unit testing￼.
    ///
    /// - Parameter visitorServiceManager: Class instance conforming to `VisitorServiceManagerProtocol`
    convenience init (context: TealiumContext,
                      delegate: ModuleDelegate?,
                      diskStorage: TealiumDiskStorageProtocol?,
                      visitorServiceManager: VisitorServiceManagerProtocol) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage) { _ in }
        self.visitorServiceManager = visitorServiceManager
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate?` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol?` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: ModuleNames.visitorservice.lowercased(), isCritical: false)
        self.visitorServiceManager = VisitorServiceManager(config: config,
                                                           delegate: config.visitorServiceDelegate,
                                                           diskStorage: self.diskStorage)
        TealiumQueues.backgroundSerialQueue.async {
            context.onVisitorId?.subscribe { [weak self] visitorId in
                guard let self = self,
                      visitorId != self.lastVisitorId
                else {
                    return
                }
                if self.lastVisitorId != nil { // actually changed id
                    self.diskStorage.delete { _, _, _ in
                        self.retrieveProfile(visitorId: visitorId)
                    }
                } else {
                    self.retrieveProfile(visitorId: visitorId) // Just first launch
                }
            }.toDisposeBag(self.bag)
        }
        completion((.success(true), nil))
    }

    private func retrieveProfile(visitorId: String) {
        self.lastVisitorId = visitorId
        self.visitorServiceManager?.requestVisitorProfile()
    }

    func retrieveProfileDelayed(visitorId: String, _ completion: (() -> Void)? = nil) {
        // wait before triggering refresh, to give event time to process
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 2.1) { [weak self] in
            self?.retrieveProfile(visitorId: visitorId)
            completion?()
        }
    }

    public func willTrack(request: TealiumRequest) {
        switch request {
        case let request as TealiumTrackRequest:
            guard let visitorId = request.visitorId else {
                return
            }
            retrieveProfileDelayed(visitorId: visitorId)
        case let request as TealiumBatchTrackRequest:
            guard let lastRequest = request.trackRequests.last,
                  let visitorId = lastRequest.visitorId else {
                return
            }
            retrieveProfileDelayed(visitorId: visitorId)
        default:
            break
        }

    }

}
