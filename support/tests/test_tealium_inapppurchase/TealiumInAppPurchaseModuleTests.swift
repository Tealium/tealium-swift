//
//  TealiumInAppPurchaseModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumInAppPurchase
@testable import TealiumCore
import StoreKit
import StoreKitTest
import XCTest

// SKTestSession.buyProduct(identifier:) is only available from iOS 17 / tvOS 17.
@available(iOS 17, tvOS 17, *)
class InAppPurchaseModuleTests: XCTestCase {

    let productId = "com.tealium.iOSTealiumTestApp.product1"
    var module: InAppPurchaseModule?
    var session: SKTestSession!
    // Written on the StoreKit Task thread and read on the test thread, so always access it through the lock.
    private let lock = NSLock()
    private var tracked = [TealiumTrackRequest]()

    var trackedRequests: [TealiumTrackRequest] {
        lock.lock()
        defer { lock.unlock() }
        return tracked
    }

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "StoreKitTesting")
        session.disableDialogs = true
        session.clearTransactions()
    }

    // Waits for the module's startup pass over Transaction.unfinished, so the pass can't pick up a purchase the test makes afterwards.
    private func startModule(storage: TealiumDiskStorageProtocol) async {
        module = makeModule(storage: storage)
        await (module?.manager as? InAppPurchaseManager)?.unfinishedTask?.value
    }

    // SKTestSession can emit a Product.purchase() result on Transaction.updates as well, and the dedup then drops the manual track.
    // Buying with no module running and finishing the purchase keeps both the updates listener and the startup pass of a module
    // created afterwards from tracking it first.
    private func purchaseWithoutListener() async throws -> Transaction {
        module = nil
        let products = try await Product.products(for: [productId])
        let product = try XCTUnwrap(products.first)
        var purchased: Transaction?
        if case .success(.verified(let transaction)) = try await product.purchase() {
            purchased = transaction
        }
        let transaction = try XCTUnwrap(purchased, "Purchase did not succeed")
        await transaction.finish()
        // In SKTestSession, Transaction.unfinished can still return the purchase right after finish(), and the startup pass of the
        // module created next would then autotrack it before the test's manual track. Finishing whatever is left prevents that.
        for await case .verified(let queued) in Transaction.unfinished {
            await queued.finish()
        }
        return transaction
    }

    // In-memory storage keeps persisted transaction ids from leaking across tests, since SKTestSession ids can repeat after clearTransactions().
    private func makeModule(storage: TealiumDiskStorageProtocol, withDelegate: Bool = true) -> InAppPurchaseModule {
        let config = TestTealiumHelper().getConfig()
        let context = TestTealiumHelper.context(with: config)
        return InAppPurchaseModule(context: context, delegate: withDelegate ? self : nil, diskStorage: storage) { _ in }
    }

    override func tearDownWithError() throws {
        module = nil
        session = nil
    }

    func testAutotrackedPurchase() async throws {
        await startModule(storage: MockTealiumDiskStorage())
        // StoreKit has no signal for when the Transaction.updates subscription is live, and on a cold process the first event can be
        // emitted before it is. Buy again until one arrives, so the test checks the tracking and not the subscription timing.
        // Polls instead of waiting on an expectation, because a timed-out wait fails the test even when a later attempt succeeds.
        var bought = [Transaction]()
        for _ in 0..<5 where trackedRequests.isEmpty {
            bought.append(try await session.buyProduct(identifier: productId))
            for _ in 0..<20 where trackedRequests.isEmpty {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        let transaction = try XCTUnwrap(bought.first { String($0.id) == trackedRequests.first?.trackDictionary["purchase_order_id"] as? String })

        // Events from earlier attempts can still arrive late, so only the matched transaction's events are counted.
        let requests = trackedRequests.filter { $0.trackDictionary["purchase_order_id"] as? String == String(transaction.id) }
        XCTAssertEqual(requests.count, 1)
        let data = try XCTUnwrap(requests.first).trackDictionary
        XCTAssertEqual(requests.first?.event, "in_app_purchase")
        XCTAssertEqual(data["autotracked"] as? Bool, true)
        XCTAssertEqual(data["purchase_order_id"] as? String, String(transaction.id))
        XCTAssertEqual(data["purchase_skus"] as? String, productId)
        XCTAssertEqual(data["purchase_quantity"] as? Int, 1)
        XCTAssertEqual(data["purchase_timestamp"] as? Date, transaction.purchaseDate)
    }

    func testUnfinishedTransactionFromBeforeStartIsTracked() async throws {
        // A listener started after a transaction arrived never gets it from Transaction.updates, so this covers Transaction.unfinished.
        let transaction = try await session.buyProduct(identifier: productId)

        await startModule(storage: MockTealiumDiskStorage())

        let requests = trackedRequests
        XCTAssertEqual(requests.count, 1)
        let data = try XCTUnwrap(requests.first).trackDictionary
        XCTAssertEqual(data["autotracked"] as? Bool, true)
        XCTAssertEqual(data["purchase_order_id"] as? String, String(transaction.id))
    }

    func testManuallyTrackedPurchase() async throws {
        let transaction = try await purchaseWithoutListener()
        await startModule(storage: MockTealiumDiskStorage())
        module?.track(.verified(transaction))

        let requests = trackedRequests
        XCTAssertEqual(requests.count, 1)
        let data = try XCTUnwrap(requests.first).trackDictionary
        XCTAssertEqual(data["autotracked"] as? Bool, false)
        XCTAssertEqual(data["purchase_order_id"] as? String, String(transaction.id))
        XCTAssertEqual(data["purchase_skus"] as? String, productId)
    }

    func testUnverifiedTransactionIsNotTracked() async throws {
        let transaction = try await purchaseWithoutListener()
        await startModule(storage: MockTealiumDiskStorage())
        module?.track(.unverified(transaction, .invalidSignature))
        XCTAssertTrue(trackedRequests.isEmpty)
    }

    func testRevokedTransactionIsNotTracked() async throws {
        let bought = try await purchaseWithoutListener()
        try session.refundTransaction(identifier: UInt(bought.id))

        // StoreKit may need a moment before the refund shows up on the latest transaction.
        var revoked: Transaction?
        for _ in 0..<20 {
            if case .verified(let latest)? = await Transaction.latest(for: productId), latest.revocationDate != nil {
                revoked = latest
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let transaction = try XCTUnwrap(revoked, "Refunded transaction never got a revocationDate")

        await startModule(storage: MockTealiumDiskStorage())
        module?.track(.verified(transaction))
        XCTAssertTrue(trackedRequests.isEmpty)
    }

    func testTrackedIdsPersistAcrossModuleRestarts() async throws {
        let transaction = try await purchaseWithoutListener()
        let storage = MockTealiumDiskStorage()
        await startModule(storage: storage)
        module?.track(.verified(transaction))
        XCTAssertEqual(trackedRequests.count, 1)

        await startModule(storage: storage)
        module?.track(.verified(transaction))
        XCTAssertEqual(trackedRequests.count, 1)
    }

    func testTrackWithoutDelegateDoesNotRecordId() async throws {
        let transaction = try await purchaseWithoutListener()
        let storage = MockTealiumDiskStorage()
        module = makeModule(storage: storage, withDelegate: false)
        module?.track(.verified(transaction))
        XCTAssertTrue(trackedRequests.isEmpty)

        await startModule(storage: storage)
        module?.track(.verified(transaction))
        let requests = trackedRequests.filter { $0.trackDictionary["purchase_order_id"] as? String == String(transaction.id) }
        XCTAssertEqual(requests.count, 1)
    }

    func testInAppPurchaseAccessorIsNotNilWhenCollectorIsSet() {
        let expect = expectation(description: "InAppPurchase not nil")
        let config = TestTealiumHelper().getConfig()
        config.collectors = [Collectors.InAppPurchase]
        var tealium: Tealium?
        tealium = Tealium(config: config) { _ in
            XCTAssertNotNil(tealium?.inAppPurchase)
            expect.fulfill()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            wait(for: [expect], timeout: 1.0)
        }
        TealiumInstanceManager.shared.removeInstance(config: config)
        tealium = nil
    }

    func testSameTransactionTrackedTwiceProducesOneEvent() async throws {
        let transaction = try await purchaseWithoutListener()
        await startModule(storage: MockTealiumDiskStorage())
        module?.track(.verified(transaction))
        module?.track(.verified(transaction))
        XCTAssertEqual(trackedRequests.count, 1)
    }

    func testPreviouslyTrackedTransactionIsNotTrackedAgain() async throws {
        let transaction = try await purchaseWithoutListener()
        let storage = MockTealiumDiskStorage()
        storage.storedData = AnyCodable([transaction.id])
        await startModule(storage: storage)

        module?.track(.verified(transaction))
        XCTAssertTrue(trackedRequests.isEmpty)
    }
}

@available(iOS 17, tvOS 17, *)
extension InAppPurchaseModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }

    func requestTrack(_ track: TealiumTrackRequest) {
        lock.lock()
        tracked.append(track)
        lock.unlock()
    }

    func requestDequeue(reason: String) { }
}
