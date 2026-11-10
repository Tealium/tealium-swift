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
    // Typed as AnyObject because a stored property can't be availability-gated. Gating the whole class would break the module on
    // OS versions below StoreKit 2 (iOS 15, macOS 12, tvOS 15, watchOS 8).
    private var manager: AnyObject?

    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        self.delegate = delegate
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            let storage = diskStorage ?? TealiumDiskStorage(config: context.config,
                                                            forModule: ModuleNames.inapppurchase.lowercased(),
                                                            isCritical: false)
            manager = InAppPurchaseManager(delegate: delegate, diskStorage: storage, logger: context.config.logger)
        } else {
            let log = TealiumLogRequest(title: "Tealium InAppPurchase",
                                        message: "In-app purchase tracking requires StoreKit 2 (iOS 15, macOS 12, tvOS 15, watchOS 8) and is disabled on this OS version.",
                                        info: nil,
                                        logLevel: .info,
                                        category: .general)
            context.config.logger?.log(log)
        }
        completion((.success(true), nil))
    }

    /// Tracks the verified transaction returned by `Product.purchase()`, which `Transaction.updates` doesn't emit.
    /// Don't pass unverified transactions. The event is `in_app_purchase` with `autotracked` set to `false`.
    ///
    /// Get this module via `tealium.inAppPurchase`. It is `nil` until Tealium has finished initializing,
    /// and `nil` if `Collectors.InAppPurchase` isn't in `config.collectors`.
    /// The app must still call `finish()`, because unfinished transactions are re-delivered through
    /// `Transaction.updates` on a later launch and would be tracked again.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func track(_ transaction: Transaction) {
        (manager as? InAppPurchaseManager)?.track(transaction, autotracked: false)
    }
}
