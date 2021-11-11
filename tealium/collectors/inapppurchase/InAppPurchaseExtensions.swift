//
//  InAppPurchaseExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import StoreKit
#if inapppurchase
import TealiumCore
#endif

public extension Collectors {
    static let InAppPurchase = InAppPurchaseModule.self
}

extension SKPaymentTransaction {
    func toTealiumEvent() -> TealiumEvent? {
        guard let transactionId = transactionIdentifier, let transactionDate = transactionDate else {
            return nil
        }
        let data: [String: Any] = [
            InAppPurchaseConstants.autotracked: true,
            InAppPurchaseConstants.purchaseOrderId: transactionId,
            InAppPurchaseConstants.purchaseTimestamp: transactionDate,
            InAppPurchaseConstants.purchaseQuantity: payment.quantity,
            InAppPurchaseConstants.purchaseSkus: payment.productIdentifier,
        ]
        let event = TealiumEvent(InAppPurchaseConstants.eventName, dataLayer: data)
        return event
    }
}

#endif
