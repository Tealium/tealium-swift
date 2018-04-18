//
//  TealiumRemoteCommandsTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumRemoteCommandsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTriggerWithUnescapedString() {
        let commandId = "test"
        let testExpectation = expectation(description: "addRemove")
        let command = TealiumRemoteCommand(commandId: commandId,
                                           description: "") { _ in

            testExpectation.fulfill()

        }

        let remoteCommands = TealiumRemoteCommands()
        remoteCommands.queue = OperationQueue.current?.underlyingQueue
        remoteCommands.enable()
        remoteCommands.add(command)

        let urlString = "tealium://\(commandId)?request={\"config\":{},\"payload\":{}}"
        let error = remoteCommands.triggerCommandFrom(urlString: urlString)
        if error != nil {
            XCTFail("Error detected: \(String(describing: error))")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testTriggerWithEscapedString() {

        let commandId = "test"
        let testExpectation = expectation(description: "addRemove")
        let command = TealiumRemoteCommand(commandId: commandId,
                                           description: "") { _ in
                    testExpectation.fulfill()
        }

        let remoteCommands = TealiumRemoteCommands()
        remoteCommands.queue = OperationQueue.current?.underlyingQueue
        remoteCommands.enable()
        remoteCommands.add(command)

        let urlString = "tealium://\(commandId)?request={\"config\":{},\"payload\":{}}"
        let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        XCTAssertTrue(escapedString != nil, "Could not escape test string.")

        let error = remoteCommands.triggerCommandFrom(urlString: escapedString!)
        if error != nil {
            XCTFail("Error detected: \(String(describing: error))")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testRemove() {
        let commandId = "test"
        let command = TealiumRemoteCommand(commandId: commandId,
                                           description: "") { _ in

                // Unused
        }

        let remoteCommands = TealiumRemoteCommands()
        remoteCommands.queue = OperationQueue.current?.underlyingQueue
        remoteCommands.enable()
        remoteCommands.add(command)

        XCTAssertTrue(remoteCommands.commands.count == 1)

        remoteCommands.remove(commandWithId: commandId)

        XCTAssertTrue(remoteCommands.commands.count == 0)
    }

    func testCommandForId() {
        let commandId = "test"
        let remoteCommand = TealiumRemoteCommand(commandId: commandId,
                                                 description: "test") { _ in
                //
        }

        let array = [remoteCommand]

        let nonexistentCommandId = "nonexistentTest"
        let noCommand = array.commandForId(nonexistentCommandId)

        XCTAssertTrue(noCommand == nil, "Actual command returned for unused command id: \(nonexistentCommandId)")

        let returnCommand = array.commandForId(commandId)
        XCTAssertTrue(returnCommand != nil, "Expected command for id: \(commandId) missing from array: \(array)")
    }

}
