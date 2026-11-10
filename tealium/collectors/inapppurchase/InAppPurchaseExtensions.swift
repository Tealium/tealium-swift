//
//  InAppPurchaseExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import StoreKit
#if inapppurchase
import TealiumCore
#endif

public extension Collectors {
    static let InAppPurchase = InAppPurchaseModule.self
}

public extension Tealium {

    /// - Returns: `InAppPurchaseModule` instance, used to manually track purchases via `track(_:)`.
    /// `nil` until Tealium has finished initializing, or if `Collectors.InAppPurchase` isn't in the config's collectors.
    var inAppPurchase: InAppPurchaseModule? {
        zz_internal_modulesManager?.modules.first {
            type(of: $0) == InAppPurchaseModule.self
        } as? InAppPurchaseModule
    }

}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Transaction {
    func toTealiumEvent(autotracked: Bool) -> TealiumEvent {
        let data: [String: Any] = [
            TealiumDataKey.inAppPurchaseAutotracked: autotracked,
            TealiumDataKey.purchaseOrderId: String(id),
            TealiumDataKey.purchaseTimestamp: purchaseDate,
            TealiumDataKey.purchaseQuantity: purchasedQuantity,
            TealiumDataKey.purchaseSkus: productID,
        ]
        return TealiumEvent(InAppPurchaseConstants.eventName, dataLayer: data)
    }
}
