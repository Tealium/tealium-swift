//
//  AttributionModule.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
#if attribution
import TealiumCore
#endif

public class AttributionModule: Collector, DispatchListener {

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
    convenience init(context: TealiumContext,
                     delegate: ModuleDelegate?,
                     diskStorage: TealiumDiskStorageProtocol?,
                     attributionData: AttributionDataProtocol) {
        self.init(context: context, delegate: delegate, diskStorage: diskStorage) { _ in }
        self.attributionData = attributionData
    }

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
        self.config = context.config
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "attribution", isCritical: false)
        self.attributionData = AttributionData(config: config,
                                               diskStorage: self.diskStorage)
        completion((.success(true), nil))
    }

    public func willTrack(request: TealiumRequest) {
        guard config.skAdAttributionEnabled else {
            return
        }
        attributionData.updateConversionValue(from: request)
    }

}
#endif
