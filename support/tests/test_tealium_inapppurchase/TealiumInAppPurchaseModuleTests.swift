//
//  TealiumInAppPurchaseModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumInAppPurchase
@testable import TealiumCore
import StoreKitTest
import XCTest

@available(iOS 14.0, *)
class InAppPurchaseModuleTests: XCTestCase {

    var module: InAppPurchaseModule?
    var context: TealiumContext!
    var expectation: XCTestExpectation?
    var payload: [String: Any]?
    var session: SKTestSession!
    var expectationRequest = XCTestExpectation(description: "Buy Product")

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "StoreKitTesting")
        session.disableDialogs = true
        session.clearTransactions()
        let config = TestTealiumHelper().getConfig()
        let context = TestTealiumHelper.context(with: config)
        SKPaymentQueue.default().add(self)
        module = InAppPurchaseModule(context: context, delegate: self, diskStorage: nil) { _ in
            
        }
    }

    override func tearDownWithError() throws {
        session = nil
    }
    
    func testStoreKitPurchase() throws {
        let request = SKProductsRequest(productIdentifiers: ["com.tealium.iOSTealiumTestApp.product1"])
        request.delegate = self
        request.start()
        wait(for: [expectationRequest], timeout: 30.0)
    }

}

@available(iOS 14.0, *)
extension InAppPurchaseModuleTests: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        SKPaymentQueue.default().add(SKPayment(product: response.products.first!))
    }

    func requestDidFinish(_ request: SKRequest) {
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        XCTFail("Failed to get product information")
        expectationRequest.fulfill()
    }
}

struct PurchaseEvent: Codable {
    let tealiumEventType: String
    let purchaseOrderId: String
    let purchaseSkus: String
    let purchaseQuantity: Int
    let requestUuid: String
    let autotracked: Bool
    let tealiumEvent: String
    let purchaseTimestamp: Date
}

@available(iOS 14.0, *)
extension InAppPurchaseModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        
    }

    func requestTrack(_ track: TealiumTrackRequest) {
        // TODO: Info and error callback handling
        XCTAssertEqual(track.event, "in_app_purchase")
        guard let purchaseSkus = track.trackDictionary["purchase_skus"] as? String, let quantity = track.trackDictionary["purchase_quantity"] as? Int, let autoTracked = track.trackDictionary["autotracked"] as? Bool, let purchaseDate = track.trackDictionary["purchase_timestamp"] as? Date else {
            XCTFail("Track data incorrect")
            expectationRequest.fulfill()
            return
        }
        XCTAssertEqual(purchaseSkus, "com.tealium.iOSTealiumTestApp.product1")
        XCTAssertEqual(quantity, 1)
        XCTAssertEqual(autoTracked, true)
        XCTAssertTrue(Date().timeIntervalSince1970 - purchaseDate.timeIntervalSince1970 < 10000)
        expectationRequest.fulfill()
    }

    func requestDequeue(reason: String) {

    }
}
