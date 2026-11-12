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
    // Guards trackedIds and sessionIds, because track(_:autotracked:) is called from the updates Task and from the app's thread.
    private let lock = NSLock()
    // Ids of the transactions already tracked, persisted as an array. Ids that are neither unfinished nor in sessionIds are dropped
    // by pruneIds(keeping:) once the startup scan completes. This assumes a finished transaction doesn't come back: Transaction.updates
    // emits a transaction when the system creates or updates it, and the documented updates (revoked, upgraded) are filtered out.
    // Apple doesn't list every kind of update, so an undocumented one to a finished transaction, such as a reversed refund, is tracked again.
    private var trackedIds: Set<UInt64>
    // Every id recorded by this manager. The manual track(_:) and Transaction.updates can both report a purchase after the app
    // has finished it, so these ids are kept for the manager's lifetime. A new manager, after a relaunch or after the module is
    // recreated, starts with none.
    private var sessionIds = Set<UInt64>()

    init(delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol, logger: TealiumLoggerProtocol?) {
        self.delegate = delegate
        self.diskStorage = diskStorage
        self.logger = logger
        self.trackedIds = Set(diskStorage.retrieve(as: [UInt64].self) ?? [])
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
            var unfinishedIds = Set<UInt64>()
            for await result in Transaction.unfinished {
                // Unverified ids are kept too. Keeping only stops an id that is already tracked from being pruned, and StoreKit can
                // still re-deliver the transaction verified later.
                unfinishedIds.insert(result.unsafePayloadValue.id)
                self?.handle(result, autotracked: true)
            }
            self?.pruneIds(keeping: unfinishedIds)
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
        guard Self.isPurchase(transaction), let delegate = delegate, recordNewId(transaction.id) else { return }
        // The app may crash between a manual track(_:) and finish(), and StoreKit then re-delivers the unfinished transaction via Transaction.updates.
        // The id is recorded before the track is requested, but the save and the request are asynchronous and unordered.
        // A crash right after this call can therefore drop the event, or, if the event was sent before the save completed,
        // let StoreKit's re-delivery track it again. Closing the window needs a delivery acknowledgement from the dispatch pipeline.
        delegate.requestTrack(transaction.toTealiumEvent(autotracked: autotracked).trackRequest)
    }

    /// Records the id as tracked and returns `false` if it already was.
    func recordNewId(_ id: UInt64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        sessionIds.insert(id)
        guard trackedIds.insert(id).inserted else { return false }
        // Saved under the lock so a slower, older snapshot can't overwrite a newer one.
        diskStorage.save(Array(trackedIds), completion: nil)
        return true
    }

    /// Drops the ids that StoreKit can no longer re-deliver, which are those that are neither unfinished nor recorded in this session.
    func pruneIds(keeping unfinishedIds: Set<UInt64>) {
        lock.lock()
        defer { lock.unlock() }
        trackedIds = trackedIds.filter { unfinishedIds.contains($0) || sessionIds.contains($0) }
        diskStorage.save(Array(trackedIds), completion: nil)
    }
}
