//
//  AttributionModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if attribution
import TealiumCore
#endif

public class AttributionModule: Collector {
    public let id: String = ModuleNames.attribution

    public var data: [String: Any]? {
        self.attributionData.allAttributionData
    }

    var attributionData: AttributionDataProtocol!
    var diskStorage: TealiumDiskStorageProtocol!
    public var config: TealiumConfig

    /// Provided for unit testing￼.
    ///
    /// - Parameter attributionData: Class instance conforming to `TealiumAttributionDataProtocol`
    convenience init(config: TealiumConfig,
                     delegate: ModuleDelegate?,
                     diskStorage: TealiumDiskStorageProtocol?,
                     attributionData: AttributionDataProtocol) {
        self.init(config: config, delegate: delegate, diskStorage: diskStorage) { _ in }
        self.attributionData = attributionData
    }

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(config: TealiumConfig,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "attribution", isCritical: false)
        self.attributionData = AttributionData(diskStorage: self.diskStorage,
                                               isSearchAdsEnabled: config.searchAdsEnabled)
        completion((.success(true), nil))
    }

}
#endif
