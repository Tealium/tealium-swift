//
//  InAppPurchaseManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import StoreKit
#if inapppurchase
import TealiumCore
#endif

class InAppPurchaseManager: NSObject, SKPaymentTransactionObserver {
    
    weak public var delegate: ModuleDelegate?

    init(delegate: ModuleDelegate?) {
        self.delegate = delegate
    }
    
    private func trackPurchase(transaction: SKPaymentTransaction) {
        if let event = transaction.toTealiumEvent() {
            delegate?.requestTrack(event.trackRequest)
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue,
                             updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                trackPurchase(transaction: transaction)
            default:
                break
            }
        }
    }
}
