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
    // Written on the test thread and read on the StoreKit Task thread, so always access it through the lock.
    private var _expectation: XCTestExpectation?
    private let lock = NSLock()
    private var tracked = [TealiumTrackRequest]()

    var expectation: XCTestExpectation? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _expectation
        }
        set {
            lock.lock()
            _expectation = newValue
            lock.unlock()
        }
    }

    var trackedRequests: [TealiumTrackRequest] {
        lock.lock()
        defer { lock.unlock() }
        return tracked
    }

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "StoreKitTesting")
        session.disableDialogs = true
        session.clearTransactions()
        module = makeModule(storage: MockTealiumDiskStorage())
        // Settle delay for the unstructured Task that subscribes to Transaction.updates, replace with a ready signal if it ever flakes.
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    // In-memory storage keeps persisted transaction ids from leaking across tests, since SKTestSession ids can repeat after clearTransactions().
    private func makeModule(storage: TealiumDiskStorageProtocol) -> InAppPurchaseModule {
        let config = TestTealiumHelper().getConfig()
        let context = TestTealiumHelper.context(with: config)
        return InAppPurchaseModule(context: context, delegate: self, diskStorage: storage) { _ in }
    }

    override func tearDownWithError() throws {
        module = nil
        session = nil
    }

    func testAutotrackedPurchase() async throws {
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

        let requests = trackedRequests
        XCTAssertEqual(requests.count, 1)
        let data = try XCTUnwrap(requests.first).trackDictionary
        XCTAssertEqual(requests.first?.event, "in_app_purchase")
        XCTAssertEqual(data["autotracked"] as? Bool, true)
        XCTAssertEqual(data["purchase_order_id"] as? String, String(transaction.id))
        XCTAssertEqual(data["purchase_skus"] as? String, productId)
        XCTAssertEqual(data["purchase_quantity"] as? Int, 1)
        XCTAssertEqual(data["purchase_timestamp"] as? Date, transaction.purchaseDate)
    }

    func testManuallyTrackedPurchase() async throws {
        let products = try await Product.products(for: [productId])
        let product = try XCTUnwrap(products.first)
        guard case .success(.verified(let transaction)) = try await product.purchase() else {
            return XCTFail("Purchase did not succeed")
        }
        let tracked = expectation(description: "Manually tracked purchase")
        tracked.assertForOverFulfill = false
        expectation = tracked
        module?.track(transaction)
        await fulfillment(of: [tracked], timeout: 10.0)

        let requests = trackedRequests
        XCTAssertEqual(requests.count, 1)
        let data = try XCTUnwrap(requests.first).trackDictionary
        XCTAssertEqual(data["autotracked"] as? Bool, false)
        XCTAssertEqual(data["purchase_order_id"] as? String, String(transaction.id))
        XCTAssertEqual(data["purchase_skus"] as? String, productId)
        await transaction.finish()
    }

    func testPurchaseFromVerifiedTransactionReturnsIt() async throws {
        let transaction = try await session.buyProduct(identifier: productId)
        XCTAssertEqual(InAppPurchaseManager.purchase(from: .verified(transaction))?.id, transaction.id)
    }

    func testPurchaseFromUnverifiedTransactionReturnsNil() async throws {
        let transaction = try await session.buyProduct(identifier: productId)
        XCTAssertNil(InAppPurchaseManager.purchase(from: .unverified(transaction, .invalidSignature)))
    }

    func testPurchaseFromRevokedTransactionReturnsNil() async throws {
        let bought = try await session.buyProduct(identifier: productId)
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
        XCTAssertNil(InAppPurchaseManager.purchase(from: .verified(transaction)))
    }

    func testSameTransactionTrackedTwiceProducesOneEvent() async throws {
        let products = try await Product.products(for: [productId])
        let product = try XCTUnwrap(products.first)
        guard case .success(.verified(let transaction)) = try await product.purchase() else {
            return XCTFail("Purchase did not succeed")
        }
        let tracked = expectation(description: "Manually tracked purchase")
        tracked.assertForOverFulfill = false
        expectation = tracked
        module?.track(transaction)
        module?.track(transaction)
        await fulfillment(of: [tracked], timeout: 10.0)
        XCTAssertEqual(trackedRequests.count, 1)
        await transaction.finish()
    }

    func testPreviouslyTrackedTransactionIsNotTrackedAgain() async throws {
        let products = try await Product.products(for: [productId])
        let product = try XCTUnwrap(products.first)
        guard case .success(.verified(let transaction)) = try await product.purchase() else {
            return XCTFail("Purchase did not succeed")
        }
        let storage = MockTealiumDiskStorage()
        storage.storedData = AnyCodable([transaction.id])
        module = makeModule(storage: storage)

        module?.track(transaction)
        XCTAssertTrue(trackedRequests.isEmpty)
        await transaction.finish()
    }
}

@available(iOS 17, tvOS 17, *)
extension InAppPurchaseModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }

    func requestTrack(_ track: TealiumTrackRequest) {
        lock.lock()
        tracked.append(track)
        let current = _expectation
        lock.unlock()
        current?.fulfill()
    }

    func requestDequeue(reason: String) { }
}
