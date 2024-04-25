//
//  MomentsAPIModule.swift
//  TealiumMoments
//
//  Created by Craig Rouse on 17/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumCore
#endif


public class TealiumMomentsAPIModule: Collector {

    public let id: String = ModuleNames.momentsapi
    public var config: TealiumConfig
    public var data: [String: Any]?
    var diskStorage: TealiumDiskStorageProtocol!
    var momentsAPI: MomentsAPI?
    private var bag = TealiumDisposeBag()

    /// Provided for unit testing￼.
    ///
    /// - Parameter visitorServiceManager: Class instance conforming to `VisitorServiceManagerProtocol`
    convenience init (context: TealiumContext,
                      delegate: ModuleDelegate?,
                      diskStorage: TealiumDiskStorageProtocol?,
                      visitorServiceManager: MomentsAPI) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage) { _ in }
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
        guard let momentsAPIRegion = config.momentsAPIRegion else {
            completion((.failure(MomentsError.missingRegion), nil))
            return
        }
        self.momentsAPI = TealiumMomentsAPI(region: momentsAPIRegion, 
                                            account: config.account,
                                            profile: config.profile,
                                            environment: config.environment)
        TealiumQueues.backgroundSerialQueue.async {
            context.onVisitorId?.subscribe { [weak self] visitorId in
                guard let self = self else {
                    return
                }
                self.momentsAPI?.visitorId = visitorId
            }.toDisposeBag(self.bag)
        }
        completion((.success(true), nil))
    }

}

public extension Collectors {
    static let Moments = TealiumMomentsAPIModule.self
}
