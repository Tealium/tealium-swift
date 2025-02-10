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
    public let delayBlock: ((@escaping () -> Void)) -> Void
    public var config: TealiumConfig
    public var data: [String: Any]?
    var diskStorage: TealiumDiskStorageProtocol!
    let visitorServiceManager: VisitorServiceManagerProtocol
    private var bag = TealiumDisposeBag()
    private var lastVisitorId: String? {
        get {
            self.visitorServiceManager.currentVisitorId
        }
        set {
            self.visitorServiceManager.currentVisitorId = newValue
        }
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate?` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol?` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    public required convenience init(context: TealiumContext,
                                     delegate: ModuleDelegate?,
                                     diskStorage: TealiumDiskStorageProtocol?,
                                     completion: ModuleCompletion) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage, visitorServiceManager: nil) { block in
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 2.1) {
                block()
            }
        }
        completion((.success(true), nil))
    }

    /// Provided for unit testing￼.
    ///
    /// - Parameter visitorServiceManager: Class instance conforming to `VisitorServiceManagerProtocol`
    init(context: TealiumContext,
         delegate: ModuleDelegate?,
         diskStorage: TealiumDiskStorageProtocol?,
         visitorServiceManager: VisitorServiceManagerProtocol?,
         delayBlock: @escaping ((@escaping () -> Void)) -> Void) {
        self.config = context.config
        self.delayBlock = delayBlock
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: ModuleNames.visitorservice.lowercased(), isCritical: false)
        self.visitorServiceManager = visitorServiceManager ?? VisitorServiceManager(config: config,
                                                                                    delegate: config.visitorServiceDelegate,
                                                                                    diskStorage: self.diskStorage)
        TealiumQueues.backgroundSerialQueue.async {
            context.onVisitorId?.subscribe { [weak self] visitorId in
                guard let self = self,
                      visitorId != self.lastVisitorId
                else {
                    return
                }
                let changedVisitorId = self.lastVisitorId != nil
                if changedVisitorId {
                    self.diskStorage.delete { _, _, _ in
                        self.retrieveProfile(visitorId: visitorId)
                    }
                } else {
                    self.retrieveProfile(visitorId: visitorId) // Just first launch
                }
            }.toDisposeBag(self.bag)
        }
    }

    func retrieveProfile(visitorId: String) {
        self.lastVisitorId = visitorId
        if shouldFetchVisitorProfile {
            self.visitorServiceManager.requestVisitorProfile()
        }
    }

    func retrieveProfileDelayed(visitorId: String, _ completion: (() -> Void)? = nil) {
        // wait before triggering refresh, to give event time to process
        delayBlock { [weak self] in
            guard visitorId == self?.lastVisitorId else { return }
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

    /// Should fetch visitor profile based on interval set in the config or defaults to every 5 minutes
    public var shouldFetchVisitorProfile: Bool {
        let lastFetch = visitorServiceManager.lastFetch
        guard let refresh = config.visitorServiceRefresh else {
            return shouldFetch(basedOn: lastFetch, interval: VisitorServiceConstants.defaultRefreshInterval.milliseconds, environment: config.environment)
        }
        return shouldFetch(basedOn: lastFetch, interval: refresh.interval.milliseconds, environment: config.environment)
    }

    /// Calculates the milliseconds since the last time the visitor profile was fetched
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - currentDate: The current date/timestamp in milliseconds
    /// - Returns: `Int64` - milliseconds since last fetch
    func intervalSince(lastFetch: Date, _ currentDate: Date = Date()) -> Int64 {
        return currentDate.millisecondsFrom(earlierDate: lastFetch)
    }

    /// Checks if the profile should be fetched based on the date of last fetch,
    /// the interval set in the config (default 5 minutes) and the current environment.
    /// If the environment is dev or qa, the profile will be fetched every tracking call.
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - interval: The interval, in milliseconds, between visitor profile retrieval
    ///   - environment: The environment set in TealiumConfig
    /// - Returns: `Bool` - whether or not the profile should be fetched
    func shouldFetch(basedOn lastFetch: Date?,
                     interval: Int64?,
                     environment: String) -> Bool {
        guard let lastFetch = lastFetch else {
            return true
        }
        guard environment == TealiumKey.prod else {
            return true
        }
        guard let interval = interval else {
            return true
        }
        let millisecondsFromLastFetch = intervalSince(lastFetch: lastFetch)
        return millisecondsFromLastFetch >= interval
    }

}
