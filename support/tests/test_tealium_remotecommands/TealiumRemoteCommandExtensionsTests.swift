//
//  TealiumRemoteCommandExtensionsTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/16/20.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandExtensionsTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        super.tearDown()
    }

    func testRemoveCommand() {
        var commands = RemoteCommandArray()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        commands = [command]
        commands.removeCommand("test123")
        XCTAssertTrue(commands.count == 0)
    }

    func testAddRemoteCommand() {
        let testHelper = TestTealiumHelper()
        let config = testHelper.getConfig()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        config.addRemoteCommand(command)
        XCTAssertTrue(config.remoteCommands?.count == 1)
    }

}
