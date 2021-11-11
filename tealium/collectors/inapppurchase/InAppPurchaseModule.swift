//
//  InAppPurchaseModule.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import StoreKit
#if inapppurchase
import TealiumCore
#endif

public class InAppPurchaseModule: Collector {

    public let id: String = ModuleNames.inapppurchase
    weak var delegate: ModuleDelegate?
    public var config: TealiumConfig
    public var data: [String: Any]?
    var inAppPurchaseManager: InAppPurchaseManager
    var diskStorage: TealiumDiskStorageProtocol!

    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        self.delegate = delegate
        self.inAppPurchaseManager = InAppPurchaseManager(delegate: delegate)
        SKPaymentQueue.default().add(inAppPurchaseManager)
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: ModuleNames.visitorservice.lowercased(), isCritical: false)
        completion((.success(true), nil))
    }
}
