//
//  RemoteCommandsManagerTests.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class RemoteCommandsManagerTests: XCTestCase {

    var tealiumLocalJSONCommand: RemoteCommandProtocol!
    var tealiumRemoteJSONCommand: RemoteCommandProtocol!
    var tealiumWebViewCommand: RemoteCommandProtocol!
    var mockDiskStorage = MockRemoteCommandsDiskStorage()
    var tealiumRemoteCommandsManager: RemoteCommandsManager!
    var payload: [String: Any]!
    var testHelper = TestTealiumHelper()

    override func setUp() {
        super.setUp()
        tealiumRemoteCommandsManager = RemoteCommandsManager(config: testHelper.getConfig(), delegate: self, urlSession: MockURLSession(), diskStorage: mockDiskStorage)
        tealiumLocalJSONCommand = RemoteCommand(commandId: "local", description: "test", type: .local(file: "example", bundle: Bundle(for: type(of: self))), completion: { _ in
            // ....
        })
        tealiumRemoteJSONCommand = RemoteCommand(commandId: "remote", description: "test", type: .remote(url: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/firebase.json")) { _ in
            // ...
        }
        tealiumWebViewCommand = RemoteCommand(commandId: "webview", description: "test", completion: { _ in
            // ...
        })
        payload = ["product_id": ["ABC123"], "product_list": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00", "event_properties": ["product_category": ["acme"], "product_name": ["cool thing"]], "tealium_event": "purchase"]
        tealiumRemoteCommandsManager.add(tealiumLocalJSONCommand)
        tealiumRemoteCommandsManager.add(tealiumRemoteJSONCommand)
        tealiumRemoteCommandsManager.add(tealiumWebViewCommand)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRefresh() {
        tealiumRemoteCommandsManager.jsonCommands.removeAll()
        tealiumRemoteCommandsManager.refresh(tealiumRemoteJSONCommand, url: URL(string: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/firebase.json")!, file: "firebase")
        XCTAssertTrue(tealiumRemoteCommandsManager.hasFetched)
        tealiumRemoteCommandsManager.jsonCommands.forEach { command in
            XCTAssertNotNil(command)
        }
    }

    func testGetCachedConfig() {
        _ = tealiumRemoteCommandsManager.cachedConfig(for: "firebase")
        XCTAssertEqual(2, mockDiskStorage.retrieveCount)
    }

    func testUpdate() {
        tealiumRemoteCommandsManager.update(command: &tealiumRemoteJSONCommand, url: URL(string: "https://tags.tiqcdn.com/dle/services-christina/mobile-test/firebase.json")!, file: "braze")
        XCTAssertEqual(tealiumRemoteJSONCommand.config?.fileName, "braze")
        XCTAssertEqual(tealiumRemoteJSONCommand.config?.commandURL, URL(string: "https://tags.tiqcdn.com/dle/services-christina/mobile-test/firebase.json")!)
    }

    func testGetAndSaveCallsHasFetched() {
        // Just see if the hasFetched was flipped to true
        tealiumRemoteCommandsManager.hasFetched = false
        tealiumRemoteCommandsManager.retrieveAndSave(tealiumRemoteJSONCommand, url: URL(string: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/firebase.json")!, file: "firebase")
        XCTAssertTrue(tealiumRemoteCommandsManager.hasFetched)
    }

    func testGetRemoteCommandConfigWith200() {
        let url = URL(string: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/firebase.json")!

        tealiumRemoteCommandsManager.remoteCommandConfig(from: url, isFirstFetch: false, lastFetch: Date()) { result in
            switch result {
            case .success(let config):
                XCTAssertNotNil(config)
            case .failure(let error):
                XCTFail("Received error: \(error.localizedDescription)")
            }
        }
    }

    func testGetRemoteCommandConfigWith304() {
        tealiumRemoteCommandsManager = RemoteCommandsManager(config: testHelper.getConfig(), delegate: self, urlSession: MockURLSession304(), diskStorage: mockDiskStorage)
        let url = URL(string: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/firebase.json")!

        tealiumRemoteCommandsManager.remoteCommandConfig(from: url, isFirstFetch: false, lastFetch: Date()) { result in
            switch result {
            case .success:
                XCTFail("Should not retrieve successful config")
            case .failure(let error):
                XCTAssertEqual(error as! TealiumRemoteCommandsError, TealiumRemoteCommandsError.notModified)
            }
        }
    }

    func testGetConfigMethodDecodesJSON() {
        let goodStub = TestTealiumHelper.loadStub(from: "example", type(of: self))
        let config = tealiumRemoteCommandsManager.config(from: goodStub)!
        let expectedMappings = ["campaign_keywords": "cp1",
                                "campaign": "campaign",
                                "checkout_option": "checkout_option",
                                "checkout_step": "checkout_step",
                                "content": "content",
                                "content_type": "content_type",
                                "coupon": "coupon",
                                "product_brand": "item_brand",
                                "product_category": "item_category",
                                "product_id": "item_id",
                                "product_list": "item_list",
                                "product_location_id": "item_location_id",
                                "product_name": "item_name",
                                "product_variant": "item_variant",
                                "campaign_medium": "medium",
                                "product_unit_price": "price",
                                "product_quantity": "quantity",
                                "search_keyword": "search_term",
                                "order_shipping_amount": "shipping",
                                "order_tax_amount": "tax",
                                "order_id": "transaction_id",
                                "order_total": "value",
                                "event_title": "event_name",
                                "event_properties": "event_parameters",
                                "tealium_event": "command_name",
                                "customer_id": "user_id"]
        XCTAssertTrue(NSDictionary(dictionary: config.mappings ?? [:]).isEqual(to: expectedMappings))

        let badStub = TestTealiumHelper.loadStub(from: "badData", type(of: self))
        guard let _ = tealiumRemoteCommandsManager.config(from: badStub) else {
            XCTAssert(true)
            return
        }
        XCTFail("should not have been successfully decoded")
    }

    func testSaveMethodGetsCalled() {
        let stub = TestTealiumHelper.loadStub(from: "example", type(of: self))
        let config = tealiumRemoteCommandsManager.config(from: stub)!
        tealiumRemoteCommandsManager.save(config, for: "example")
        XCTAssertEqual(2, mockDiskStorage.saveCount)
    }

    func testAddLocalCommandAddsCommandToArray() {
        tealiumRemoteCommandsManager.jsonCommands.removeAll()
        tealiumRemoteCommandsManager.add(tealiumLocalJSONCommand)
        XCTAssertNotNil(tealiumRemoteCommandsManager.jsonCommands.first?.config)
        XCTAssertEqual(1, tealiumRemoteCommandsManager.jsonCommands.count)
    }

    func testAddRemoteCommandAddsLocalCommand() {
        tealiumRemoteCommandsManager.jsonCommands.removeAll()
        tealiumRemoteCommandsManager.add(tealiumRemoteJSONCommand)
        XCTAssertNotNil(tealiumRemoteCommandsManager.jsonCommands.first?.config)
        XCTAssertEqual(1, tealiumRemoteCommandsManager.jsonCommands.count)
    }

    func testAddRemoteCommandCallsGetCachedConfig() {
        tealiumRemoteCommandsManager.add(tealiumRemoteJSONCommand)
        XCTAssertEqual(2, mockDiskStorage.retrieveCount)
        XCTAssertEqual(1, mockDiskStorage.saveCount)
    }

    func testRemoveJsonCommandRemovesCommandFromArray() {
        tealiumRemoteCommandsManager.jsonCommands = [tealiumLocalJSONCommand, tealiumRemoteJSONCommand]
        XCTAssertEqual(2, tealiumRemoteCommandsManager.jsonCommands.count)
        tealiumRemoteCommandsManager.remove(jsonCommand: "firebase")
        XCTAssertEqual(1, tealiumRemoteCommandsManager.jsonCommands.count)
    }

    func testRemove() {
        let commandId = "test"
        let command = RemoteCommand(commandId: commandId,
                                    description: "") { _ in

            // Unused
        }

        let remoteCommands = RemoteCommandsManager(config: testHelper.getConfig(),
                                                   delegate: self)
        remoteCommands.queue = OperationQueue.current?.underlyingQueue
        remoteCommands.add(command)

        XCTAssertTrue(remoteCommands.webviewCommands.count == 1)

        remoteCommands.remove(commandWithId: commandId)

        XCTAssertTrue(remoteCommands.webviewCommands.count == 0)
    }

    func testCommandForId() {
        let commandId = "test"
        let remoteCommand: RemoteCommandProtocol = RemoteCommand(commandId: commandId,
                                                                 description: "test") { _ in
            //
        }

        let array = [remoteCommand]

        let nonexistentCommandId = "nonexistentTest"
        let noCommand = array[nonexistentCommandId]

        XCTAssertTrue(noCommand == nil, "Actual command returned for unused command id: \(nonexistentCommandId)")

        let returnCommand = array[commandId]
        XCTAssertTrue(returnCommand != nil, "Expected command for id: \(commandId) missing from array: \(array)")
    }

    func testTriggerCommandWithPayload() {
        let mockDelegate = MockRemoteCommandDelegate()
        let expect = expectation(description: "delegate method is executed")
        let data: [String: Any] = ["js_result": ["hello": "world"], "payload": payload]
        tealiumRemoteCommandsManager.jsonCommands = [tealiumLocalJSONCommand]
        tealiumRemoteCommandsManager.jsonCommands.forEach { command in
            var command = command
            command.delegate = mockDelegate
            mockDelegate.asyncExpectation = expect
            tealiumRemoteCommandsManager.trigger(command: .JSON, with: data, completion: nil)
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockDelegate.remoteCommandResult else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertNotNil(result)
            XCTAssertFalse(result.payload!.isEmpty)
        }

    }

    func testTriggerCommandWithoutPayload() {
        let mockDelegate = MockRemoteCommandDelegate()
        let expect = expectation(description: "delegate method is executed")
        tealiumRemoteCommandsManager.jsonCommands = [tealiumLocalJSONCommand]
        tealiumRemoteCommandsManager.jsonCommands.forEach { command in
            var command = command
            command.delegate = mockDelegate
            mockDelegate.asyncExpectation = expect
            tealiumRemoteCommandsManager.trigger(command: .JSON, with: payload, completion: nil)
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockDelegate.remoteCommandResult else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertNotNil(result)
            XCTAssertFalse(result.payload!.isEmpty)
        }
    }

    func testRemoveAll() {
        XCTAssertEqual(tealiumRemoteCommandsManager.jsonCommands.count, 2)
        XCTAssertEqual(tealiumRemoteCommandsManager.webviewCommands.count, 1)
        tealiumRemoteCommandsManager.removeAll()
        XCTAssertEqual(tealiumRemoteCommandsManager.jsonCommands.count, 0)
        XCTAssertEqual(tealiumRemoteCommandsManager.webviewCommands.count, 0)
    }

    func testTriggerCommandFromRequestWhenSchemeDoesNotEqualTealium() {
        let expected: TealiumRemoteCommandsError = .invalidScheme
        let urlString = "https://www.tealium.com"

        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let actual = tealiumRemoteCommandsManager.triggerCommand(from: urlRequest)
        XCTAssertEqual(actual, expected)
    }

    func testTriggerCommandFromRequestWhenCommandIdNotPresent() {
        let expected: TealiumRemoteCommandsError = .commandIdNotFound
        let urlString = "tealium://"

        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let actual = tealiumRemoteCommandsManager.triggerCommand(from: urlRequest)
        XCTAssertEqual(actual, expected)
    }

    func testTriggerCommandFromRequestWhenNoCommandFound() {
        let expected: TealiumRemoteCommandsError = .commandNotFound
        let urlString =  "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"

        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let actual = tealiumRemoteCommandsManager.triggerCommand(from: urlRequest)
        XCTAssertEqual(actual, expected)
    }

    func testTriggerCommandFromRequestWhenRequestNotProperlyFormatted() {
        let expected: TealiumRemoteCommandsError = .requestNotProperlyFormatted
        let urlString = "tealium://webview?something={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let actual = tealiumRemoteCommandsManager.triggerCommand(from: urlRequest)
        XCTAssertEqual(actual, expected)
    }

    func testTriggerCommandFromRequestSetsPendingResponseToTrueAndTriggersDelegate() {
        let urlString = "tealium://webview?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"

        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let mockDelegate = MockRemoteCommandDelegate()
        let expect = expectation(description: "delegate method is executed")
        tealiumRemoteCommandsManager.webviewCommands.forEach { command in
            var command = command
            command.delegate = mockDelegate
            mockDelegate.asyncExpectation = expect

            tealiumRemoteCommandsManager.triggerCommand(from: urlRequest)

            XCTAssertEqual(RemoteCommandsManager.pendingResponses.value["123"], true)
        }
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockDelegate.remoteCommandResult else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertNotNil(result)
            XCTAssertFalse(result.payload!.isEmpty)
        }
    }

}

extension RemoteCommandsManagerTests: ModuleDelegate {
    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }
}
