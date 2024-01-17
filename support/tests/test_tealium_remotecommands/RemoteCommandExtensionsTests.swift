//
//  RemoteCommandExtensionsTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumRemoteCommands
import XCTest

class RemoteCommandExtensionsTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        super.tearDown()
    }

    func testRemoveCommand() {
        var commands = [RemoteCommandProtocol]()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        let webViewCommand = RemoteCommand(commandId: "webviewTest123", description: "test") { _ in
            // ...
        }
        commands = [command, webViewCommand]
        commands.removeCommand("test123")
        commands.removeCommand("webviewTest123")
        XCTAssertTrue(commands.count == 0)
    }

    func testAddRemoteCommand() {
        let testHelper = TestTealiumHelper()
        let config = testHelper.getConfig()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        let webViewCommand = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        config.addRemoteCommand(webViewCommand)
        config.addRemoteCommand(command)
        XCTAssertTrue(config.remoteCommands?.count == 2)
    }

    func testIsValidURL() {
        let validURLString = "https://www.tealium.com"
        let anotherValidURLString = "https://www.tealium.com/?test=test&key=value"
        let invalidURLString = "😫😫😫😫😫"
        let anotherInvalidURLString = "&%*#*(#@($)#*#@(&%(&@#%(&$3253"
        XCTAssertTrue(validURLString.isValidUrl)
        XCTAssertTrue(anotherValidURLString.isValidUrl)
        XCTAssertFalse(invalidURLString.isValidUrl)
        XCTAssertFalse(anotherInvalidURLString.isValidUrl)
    }

    func testCacheBuster() {
        let urlString = "https://www.tealium.com"
        XCTAssertTrue(urlString.cacheBuster.starts(with: "https://www.tealium.com?_cb="))
    }

    func testRemoteCommandsErrorLocalizedDescription() {
        let error: Error = TealiumRemoteCommandsError.commandsNotFound
        XCTAssertEqual(error.localizedDescription, "TealiumRemoteCommandsError.commandsNotFound")
    }
}
