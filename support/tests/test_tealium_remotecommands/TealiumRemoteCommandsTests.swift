//
//  TealiumRemoteCommandsManagerTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/16/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandsManagerTests: XCTestCase {

    var tealiumRemoteCommandsManager: RemoteCommandsManager!

    override func setUp() {
        super.setUp()
        let rc = RemoteCommand(commandId: "webview", description: "test") { _ in }
        tealiumRemoteCommandsManager = RemoteCommandsManager(delegate: self)
        tealiumRemoteCommandsManager.add(rc)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRemove() {
        let commandId = "test"
        let command = RemoteCommand(commandId: commandId,
                                    description: "") { _ in }

        let remoteCommandsManager = RemoteCommandsManager(delegate: nil)
        remoteCommandsManager.queue = OperationQueue.current?.underlyingQueue
        remoteCommandsManager.add(command)

        XCTAssertTrue(remoteCommandsManager.commands.count == 1)

        remoteCommandsManager.remove(commandWithId: commandId)

        XCTAssertTrue(remoteCommandsManager.commands.isEmpty)
    }

    func testCommandForId() {
        let commandId = "test"
        let remoteCommand = RemoteCommand(commandId: commandId,
                                          description: "test") { _ in }

        let array = [remoteCommand]

        let nonexistentCommandId = "nonexistentTest"
        let noCommand = array.commandForId(nonexistentCommandId)

        XCTAssertTrue(noCommand == nil, "Actual command returned for unused command id: \(nonexistentCommandId)")

        let returnCommand = array.commandForId(commandId)
        XCTAssertTrue(returnCommand != nil, "Expected command for id: \(commandId) missing from array: \(array)")
    }

    func testRemoveAll() {
        XCTAssertEqual(tealiumRemoteCommandsManager.commands.count, 1)
        tealiumRemoteCommandsManager.removeAll()
        XCTAssertEqual(tealiumRemoteCommandsManager.commands.count, 0)
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
        let expected: TealiumRemoteCommandsError = .noCommandIdFound
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
        let expected: TealiumRemoteCommandsError = .noCommandForCommandIdFound
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"

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
        tealiumRemoteCommandsManager.commands.forEach { command in
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

extension TealiumRemoteCommandsManagerTests: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }
}
