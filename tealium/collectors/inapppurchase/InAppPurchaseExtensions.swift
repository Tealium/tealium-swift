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

@available(watchOS 6.2, *)
public extension Collectors {
    static let InAppPurchase = InAppPurchaseModule.self
}

@available(watchOS 6.2, *)
extension SKPaymentTransaction {
    func toTealiumEvent() -> TealiumEvent? {
        guard let transactionId = transactionIdentifier, let transactionDate = transactionDate else {
            return nil
        }
        let data: [String: Any] = [
            TealiumDataKey.inAppPurchaseAutotracked: true,
            TealiumDataKey.purchaseOrderId: transactionId,
            TealiumDataKey.purchaseTimestamp: transactionDate,
            TealiumDataKey.purchaseQuantity: payment.quantity,
            TealiumDataKey.purchaseSkus: payment.productIdentifier,
        ]
        let event = TealiumEvent(InAppPurchaseConstants.eventName, dataLayer: data)
        return event
    }
}
