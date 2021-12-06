//
//  InAppPurchaseConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

enum InAppPurchaseConstants {
    static let eventName = "in_app_purchase"
}

extension TealiumDataKey {
    static let purchaseOrderId = "purchase_order_id"
    static let purchaseTimestamp = "purchase_timestamp"
    static let purchaseQuantity = "purchase_quantity"
    static let purchaseSkus = "purchase_skus"
    static let inAppPurchaseAutotracked = "autotracked"
}
