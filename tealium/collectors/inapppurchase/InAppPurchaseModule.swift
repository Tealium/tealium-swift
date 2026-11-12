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
    private(set) var manager: AnyObject?

    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        self.delegate = delegate
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            // The dedup ids must survive relaunches even when config.diskStorageEnabled is false, or unfinished transactions are re-tracked on every launch.
            let storage = diskStorage ?? TealiumDiskStorage(config: context.config,
                                                            forModule: ModuleNames.inapppurchase.lowercased(),
                                                            isCritical: true)
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

    /// Tracks a purchase made by the app. Pass the `VerificationResult` from the app's own purchase call, such as the value in
    /// `Product.PurchaseResult.success(_:)`, `purchase(confirmIn:)`, `PurchaseAction`, or a StoreKit view's `onInAppPurchaseCompletion`.
    /// StoreKit returns those purchases to the caller and doesn't promise to emit them through `Transaction.updates`,
    /// so they may not be autotracked. If `Transaction.updates` emits one as well, only one event is sent, and `autotracked`
    /// reflects whichever path tracked it first.
    /// Purchases from StoreKit views without `onInAppPurchaseCompletion` go through `Transaction.updates` and are autotracked.
    /// Unverified results are skipped and logged. Revoked, upgraded, family-shared and assigned transactions are ignored.
    /// The event is `in_app_purchase`, with `autotracked` set to `false` when tracked here.
    ///
    /// A transaction is ignored if it was already tracked since the module started, or if it was tracked earlier and is still
    /// unfinished. A finished transaction from an earlier launch is tracked again, so pass only the results of new purchases.
    /// Don't pass results from `Transaction.currentEntitlements` or `Transaction.all`, even from a handler shared with
    /// `Transaction.updates`, because they return finished transactions on every launch.
    ///
    /// `Transaction.updates` also emits purchases the customer made in the app on another device,
    /// so each device sends its own event with the same `purchase_order_id`. Dedupe on `purchase_order_id` downstream
    /// when counting revenue.
    ///
    /// Get this module via `tealium.inAppPurchase`. It is `nil` until Tealium has finished initializing,
    /// and `nil` if `Collectors.InAppPurchase` isn't in `config.collectors`.
    /// Tealium never calls `finish()`, so the app still has to after delivering the content.
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    public func track(_ result: VerificationResult<Transaction>) {
        (manager as? InAppPurchaseManager)?.handle(result, autotracked: false)
    }
}
