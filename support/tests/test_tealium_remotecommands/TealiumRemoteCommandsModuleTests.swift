//
//  TealiumRemoteCommandsModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

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
        config.disableRemoteHTTPCommand()
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
        config.enableRemoteHTTPCommand()
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
        let notification = Notification(name: Notification.Name(TealiumKey.tagmanagementNotification),
                                        object: nil,
                                        userInfo: [TealiumKey.tagmanagementNotification: urlRequest])
        module.trigger(sender: notification)

        waitForExpectations(timeout: 5.0, handler: nil)

        XCTAssertTrue(1 == 1, "Remote command completion block successfully triggered.")
    }

}
