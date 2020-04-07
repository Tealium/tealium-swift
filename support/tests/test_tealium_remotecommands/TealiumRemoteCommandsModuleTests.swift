//
//  TealiumRemoteCommandsModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandsModuleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumRemoteCommandsModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testDisableHTTPCommandsViaConfig() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.remoteHTTPCommandDisabled = true
        let module = TealiumRemoteCommandsModule(delegate: nil)
        module.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        XCTAssertTrue(module.remoteCommands?.commands.count == 0, "Unexpected number of reserve commands found: \(String(describing: module.remoteCommands?.commands))")
    }

    // Integration Test
    func testMockTriggerFromNotification() {
        // Spin up module
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.remoteHTTPCommandDisabled = false
        let module = TealiumRemoteCommandsModule(delegate: nil)
        module.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        // Add remote command
        let testExpectation = expectation(description: "triggerTest")
        let commandId = "test"
        let remoteCommand = TealiumRemoteCommand(commandId: commandId,
                                                 description: "") { _ in
                                                    testExpectation.fulfill()
        }
        module.remoteCommands?.add(remoteCommand)

        // Send trigger
        let urlString = "tealium://\(commandId)?request={\"config\":{}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)
        let notification = Notification(name: Notification.Name.tagmanagement,
                                        object: nil,
                                        userInfo: [TealiumKey.tagmanagementNotification: urlRequest])
        module.remoteCommands!.triggerCommandFrom(notification: notification)

        waitForExpectations(timeout: 5.0, handler: nil)

        XCTAssertTrue(1 == 1, "Remote command completion block successfully triggered.")
    }

    func testUpdateConfig() {
        // Spin up module
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.remoteHTTPCommandDisabled = false
        let module = TealiumRemoteCommandsModule(delegate: nil)
        let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
        module.enable(enableRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        var newRemoteCommand = TealiumRemoteCommand(commandId: "test", description: "test") { _ in

        }
        var newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 2)
        newRemoteCommand = TealiumRemoteCommand(commandId: "test2", description: "test") { _ in

        }
        newConfig.remoteCommands = nil
        newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 3)
    }

    func testEnableWithDefaultCommands() {
        // Spin up module
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.remoteHTTPCommandDisabled = false
        let module = TealiumRemoteCommandsModule(delegate: nil)
        let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
        module.enable(enableRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        module.disable(TealiumDisableRequest())
        XCTAssertNil(module.remoteCommands)
        module.enable(enableRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
    }

    func testEnableDefaultCommandsDisabled() {
        // Spin up module
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.remoteHTTPCommandDisabled = true
        let module = TealiumRemoteCommandsModule(delegate: nil)
        let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
        module.enable(enableRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 0)
        module.disable(TealiumDisableRequest())
        XCTAssertNil(module.observer)
        XCTAssertNil(module.remoteCommands)
        module.enable(enableRequest)
        XCTAssertNotNil(module.observer)
        XCTAssertEqual(module.remoteCommands?.commands.count, 0)
    }

}
