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

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
final class InAppPurchaseManager {

    weak var delegate: ModuleDelegate?
    private var updatesTask: Task<Void, Never>?
    private let diskStorage: TealiumDiskStorageProtocol
    // Keeps only the 100 most recent ids, which is plenty for crash-before-finish re-deliveries. Raise it if older duplicates show up.
    private let maxTrackedIds = 100
    // Guards trackedIds, because track(_:autotracked:) is called from the updates Task and from the app's thread.
    private let lock = NSLock()
    private var trackedIds: [UInt64]

    init(delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol, logger: TealiumLoggerProtocol?) {
        self.delegate = delegate
        self.diskStorage = diskStorage
        self.trackedIds = diskStorage.retrieve(as: [UInt64].self) ?? []
        // Transaction.updates doesn't emit the result of Product.purchase() calls made by this app. Those are tracked via the module's track(_:).
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case let .unverified(transaction, error) = result {
                    let log = TealiumLogRequest(title: "Tealium InAppPurchase",
                                                message: "Skipping unverified transaction \(transaction.id): \(error)",
                                                info: nil,
                                                logLevel: .info,
                                                category: .general)
                    logger?.log(log)
                }
                guard let transaction = Self.purchase(from: result) else { continue }
                self?.track(transaction, autotracked: true)
            }
        }
    }

    // Unverified results may be tampered with.
    static func purchase(from result: VerificationResult<Transaction>) -> Transaction? {
        guard case let .verified(transaction) = result, isPurchase(transaction) else {
            return nil
        }
        return transaction
    }

    // Revoked and upgraded transactions are no longer revenue, and family-shared ones belong to another user's purchase.
    // Also checked in track(_:autotracked:), because the public manual track(_:) doesn't go through purchase(from:).
    static func isPurchase(_ transaction: Transaction) -> Bool {
        transaction.revocationDate == nil && !transaction.isUpgraded && transaction.ownershipType != .familyShared
    }

    deinit {
        updatesTask?.cancel()
    }

    func track(_ transaction: Transaction, autotracked: Bool) {
        guard Self.isPurchase(transaction) else { return }
        // The app may crash between a manual track(_:) and finish(), and StoreKit then re-delivers the unfinished transaction via Transaction.updates.
        // The id is persisted before the event is durable, so a crash in that short window drops the event instead of
        // double-counting it. Closing the window needs a delivery acknowledgement from the dispatch pipeline.
        lock.lock()
        guard !trackedIds.contains(transaction.id) else {
            lock.unlock()
            return
        }
        trackedIds.append(transaction.id)
        trackedIds = Array(trackedIds.suffix(maxTrackedIds))
        // Saved under the lock so a slower, older snapshot can't overwrite a newer one.
        diskStorage.save(trackedIds, completion: nil)
        lock.unlock()
        delegate?.requestTrack(transaction.toTealiumEvent(autotracked: autotracked).trackRequest)
    }
}
