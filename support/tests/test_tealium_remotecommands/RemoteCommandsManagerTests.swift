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

    var mockDiskStorage = MockTealiumDiskStorage()
    var testHelper = TestTealiumHelper()
    let mockURLSession = MockURLSession()
    lazy var config = testHelper.getConfig().copy
    lazy var tealiumRemoteCommandsManager = RemoteCommandsManager(config: config, delegate: self, urlSession: mockURLSession, diskStorage: mockDiskStorage)
    lazy var tealiumLocalJSONCommand = RemoteCommand(commandId: "local", description: "test", type: .local(file: "example", bundle: Bundle(for: type(of: self))), completion: { _ in
        // ....
    })
    lazy var tealiumRemoteJSONCommand = RemoteCommand(commandId: "example", description: "test", type: .remote(url: "https://tags.tiqcdn.com/dle/services-christina/tagbridge/example.json")) { _ in
        // ...
    }
    lazy var tealiumWebViewCommand = RemoteCommand(commandId: "webview", description: "test", completion: { _ in
        // ...
    })
    lazy var payload: [String: Any] = ["product_id": ["ABC123"], "product_list": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00", "event_properties": ["product_category": ["acme"], "product_name": ["cool thing"]], "tealium_event": "purchase"]
    
    override func setUp() {
        mockURLSession.result = .success(withData: TestTealiumHelper.loadStub(from: "example", type(of: self)))
    }

    func addRemoteCommands(_ remoteCommands: RemoteCommand...) {
        TealiumQueues.backgroundSerialQueue.sync {
            for remoteCommand in remoteCommands {
                tealiumRemoteCommandsManager.add(remoteCommand)
            }
        }
    }

    func testRemoteCommandRefreshedAtStart() {
        addRemoteCommands(tealiumRemoteJSONCommand)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertNotNil(tealiumRemoteJSONCommand.config)
        }
    }

    func testRemoteCommandReadFromCacheAtStart() {
        mockDiskStorage.storedData = AnyCodable(RemoteCommandConfig(config: [:], mappings: [:], apiCommands: [:], statics: [:], commandName: nil, commandURL: nil))
        mockURLSession.result = .success(withData: nil)
        addRemoteCommands(tealiumRemoteJSONCommand)
        XCTAssertNotNil(tealiumRemoteJSONCommand.config)
    }

    func testGetConfigMethodDecodesJSON() {
        let goodStub = TestTealiumHelper.loadStub(from: "example", type(of: self))
        let config = RemoteCommandsManager.config(from: goodStub, etag: nil)!
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
        guard let _ = RemoteCommandsManager.config(from: badStub, etag: nil) else {
            XCTAssert(true)
            return
        }
        XCTFail("should not have been successfully decoded")
    }

    func testAddLocalCommandAddsCommandToArray() {
        addRemoteCommands(tealiumLocalJSONCommand)
        XCTAssertNotNil(tealiumRemoteCommandsManager.jsonCommands.first?.config)
        XCTAssertEqual(1, tealiumRemoteCommandsManager.jsonCommands.count)
    }

    func testAddRemoteCommandCallsGetCachedConfig() {
        let cmd = RemoteCommand(commandId: "newId", description: tealiumRemoteJSONCommand.description, type: tealiumRemoteJSONCommand.type, completion: tealiumRemoteJSONCommand.completion)
        addRemoteCommands(cmd)
        XCTAssertEqual(1, mockDiskStorage.retrieveCount, "Cache should be tried to be read on newId remote commands")
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(1, mockDiskStorage.saveCount, "Save should be called for newId remote command")
            XCTAssertNotNil(cmd.config)
        }
    }
    
    func testAddRemoteCommandDoesntDeleteConfig() {
        let fileName = "testName"
        let command = RemoteCommand(commandId: "id", description: nil, type: .remote(url: "https://testName.com")) { response in

        }
        command.config = RemoteCommandConfig(config: ["fileName": fileName], mappings: [:], apiCommands: [:], statics: [:], commandName: fileName, commandURL: nil)
        XCTAssertNotNil(command.config)
        addRemoteCommands(command)
        XCTAssertNotNil(command.config)
    }
    
    func testAddCommandsWithSameIdDoesReplacesCommands() {
        addRemoteCommands(tealiumLocalJSONCommand, tealiumLocalJSONCommand, tealiumWebViewCommand)
        let currentJSONCommandCount = tealiumRemoteCommandsManager.jsonCommands.count
        let webviewCommandId = tealiumRemoteCommandsManager.webviewCommands.first!.commandId
        let jsonCommandId = tealiumRemoteCommandsManager.jsonCommands.first!.commandId
        addRemoteCommands(RemoteCommand(commandId: webviewCommandId, description: nil, completion: { _ in }),
                          RemoteCommand(commandId: webviewCommandId, description: nil, type: .remote(url: "www.google.com"), completion: { _ in }),
                          RemoteCommand(commandId: jsonCommandId, description: nil, type: .remote(url: "www.google.com"), completion: { _ in }),
                          RemoteCommand(commandId: jsonCommandId, description: nil, type: .local(file: "somePath", bundle: .main), completion: { _ in })
        )
        XCTAssertEqual(tealiumRemoteCommandsManager.jsonCommands.count, currentJSONCommandCount)
    }

    func testRemoveJsonCommandRemovesCommandFromArray() {
        addRemoteCommands(tealiumLocalJSONCommand, tealiumRemoteJSONCommand)
        XCTAssertEqual(2, tealiumRemoteCommandsManager.jsonCommands.count)
        tealiumRemoteCommandsManager.remove(jsonCommand: "example")
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
        addRemoteCommands(tealiumLocalJSONCommand, tealiumRemoteJSONCommand)
        TealiumQueues.backgroundSerialQueue.sync {
            expect.expectedFulfillmentCount = tealiumRemoteCommandsManager.jsonCommands.count
            tealiumRemoteCommandsManager.jsonCommands.forEach { command in
                var command = command
                command.delegate = mockDelegate
                mockDelegate.asyncExpectation = expect
            }
            tealiumRemoteCommandsManager.trigger(command: .JSON, with: data, completion: nil)
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

    func testTriggerCommandWithoutPayload() {
        let mockDelegate = MockRemoteCommandDelegate()
        let expect = expectation(description: "delegate method is executed")
        addRemoteCommands(tealiumLocalJSONCommand, tealiumLocalJSONCommand)
        TealiumQueues.backgroundSerialQueue.sync {
            expect.expectedFulfillmentCount = tealiumRemoteCommandsManager.jsonCommands.count
            tealiumRemoteCommandsManager.jsonCommands.forEach { command in
                var command = command
                command.delegate = mockDelegate
                mockDelegate.asyncExpectation = expect
            }
            tealiumRemoteCommandsManager.trigger(command: .JSON, with: payload, completion: nil)
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

    func testRemoveAll() {
        addRemoteCommands(tealiumLocalJSONCommand, tealiumRemoteJSONCommand, tealiumWebViewCommand)
        XCTAssertEqual(tealiumRemoteCommandsManager.jsonCommands.count, 2)
        XCTAssertEqual(tealiumRemoteCommandsManager.webviewCommands.count, 1)
        tealiumRemoteCommandsManager.removeAll()
        XCTAssertEqual(tealiumRemoteCommandsManager.jsonCommands.count, 0)
        XCTAssertEqual(tealiumRemoteCommandsManager.webviewCommands.count, 0)
    }

    func testTriggerCommandFromRequestWhenSchemeDoesNotEqualTealium() {
        let expected: TealiumRemoteCommandsError = .invalidScheme
        addRemoteCommands(tealiumWebViewCommand)
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
        addRemoteCommands(tealiumWebViewCommand)
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
        addRemoteCommands(tealiumWebViewCommand)
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
        addRemoteCommands(tealiumWebViewCommand)
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
        addRemoteCommands(tealiumWebViewCommand)
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

    func testGetPayaloadDataWithPayload() {
        let innerData = ["someKey": "anything"]
        let data: [String: Any] = [
            RemoteCommandsKey.payload: innerData,
            TealiumDataKey.eventType: TealiumTrackType.event.description
        ]
        let payload = tealiumRemoteCommandsManager.getPayloadData(data: data)
        XCTAssertTrue(payload.contains { $0.0 == "someKey"})
        XCTAssertTrue(payload.contains { $0.0 == TealiumDataKey.eventType})
    }

    func testGetPayloadDataWithoutPayload() {
        let data: [String: Any] = [
            "someKey": "someValue",
            TealiumDataKey.eventType: TealiumTrackType.event.description
        ]
        let payload = tealiumRemoteCommandsManager.getPayloadData(data: data)
        XCTAssertEqual(payload as? [String: String], data as? [String: String])
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
