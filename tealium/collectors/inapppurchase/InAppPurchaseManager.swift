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
    // Internal so tests can wait for the startup pass over Transaction.unfinished before they make purchases of their own.
    private(set) var unfinishedTask: Task<Void, Never>?
    private let diskStorage: TealiumDiskStorageProtocol
    private let logger: TealiumLoggerProtocol?
    // The startup scan re-emits every unfinished transaction on every launch, so this must stay above the number of transactions an app
    // leaves unfinished. Once they outnumber it, FIFO eviction makes all of them look new again and every one is re-tracked on each launch.
    // 1000 ids is about 20 KB persisted.
    private let maxTrackedIds = 1000
    // Guards trackedIds, because track(_:autotracked:) is called from the updates Task and from the app's thread.
    private let lock = NSLock()
    private var trackedIds: [UInt64]

    init(delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol, logger: TealiumLoggerProtocol?) {
        self.delegate = delegate
        self.diskStorage = diskStorage
        self.logger = logger
        self.trackedIds = diskStorage.retrieve(as: [UInt64].self) ?? []
        // StoreKit returns purchases made on this device to the app's purchase call and doesn't promise to emit them here,
        // so those are also tracked by the app via the module's track(_:). The dedup in track(_:autotracked:) keeps it to one event.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                self?.handle(result, autotracked: true)
            }
        }
        // Transaction.updates delivers unfinished transactions once, right after app launch, which can be before Tealium starts
        // the listener above. The ones the app hasn't finished yet are still in Transaction.unfinished. A transaction the app
        // finishes before this runs can't be seen here.
        // Overlap with the listener above is removed by the dedup in track(_:autotracked:).
        unfinishedTask = Task { [weak self] in
            for await result in Transaction.unfinished {
                self?.handle(result, autotracked: true)
            }
        }
    }

    func handle(_ result: VerificationResult<Transaction>, autotracked: Bool) {
        switch result {
        case .verified(let transaction):
            track(transaction, autotracked: autotracked)
        case let .unverified(transaction, error):
            // Unverified results may be tampered with.
            let log = TealiumLogRequest(title: "Tealium InAppPurchase",
                                        message: "Skipping unverified transaction \(transaction.id): \(error)",
                                        info: nil,
                                        logLevel: .info,
                                        category: .general)
            logger?.log(log)
        }
    }

    // Revoked and upgraded transactions are no longer revenue. Family-shared and assigned (organization seat) ones mirror
    // someone else's purchase. Requiring .purchased also rejects ownership types added in later OS versions.
    private static func isPurchase(_ transaction: Transaction) -> Bool {
        transaction.revocationDate == nil && !transaction.isUpgraded && transaction.ownershipType == .purchased
    }

    deinit {
        updatesTask?.cancel()
        unfinishedTask?.cancel()
    }

    func track(_ transaction: Transaction, autotracked: Bool) {
        // Without a delegate no event can be sent, so the id isn't recorded and a later instance can still track the transaction.
        guard Self.isPurchase(transaction), let delegate = delegate else { return }
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
        delegate.requestTrack(transaction.toTealiumEvent(autotracked: autotracked).trackRequest)
    }
}
