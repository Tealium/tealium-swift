//
//  RemoteCommandsModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class RemoteCommandsModuleTests: XCTestCase {

    let helper = TestTealiumHelper()
    var config: TealiumConfig!
    var module: RemoteCommandsModule!
    var remoteCommandsManager = MockRemoteCommandsManager()
    let remoteCommand = MockRemoteCommand()
    var processExpectation: XCTestExpectation?

    override func setUp() {
        super.setUp()
        config = helper.getConfig()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDisableHTTPCommandsViaConfig() {
        config.remoteHTTPCommandDisabled = true
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        guard let remoteCommands = module.remoteCommands else {
            XCTFail("remoteCommands array should not be nil")
            return
        }

        XCTAssertTrue((remoteCommands.commands.isEmpty), "Unexpected number of reserve commands found: \(String(describing: module.remoteCommands?.commands))")
    }

    // Integration Test
    func testMockProcessTealiumRemoteCommandRequest() {
        processExpectation = expectation(description: "testMockProcessTealiumRemoteCommandRequest")
        config.remoteHTTPCommandDisabled = false

        module = RemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        // Add remote command
        let commandId = "test"
        let remoteCommand = RemoteCommand(commandId: commandId,
                                          description: "") { _ in }
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
        let request = TealiumRemoteCommandRequest(data: [TealiumKey.tagmanagementNotification: urlRequest])
        module.remoteCommands?.moduleDelegate?.processRemoteCommandRequest(request)

        waitForExpectations(timeout: 5.0, handler: nil)

        XCTAssertTrue(1 == 1, "Remote command completion block successfully triggered.")
    }

    func testUpdateConfig() {
        config.remoteHTTPCommandDisabled = false
        module = RemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        var newRemoteCommand = RemoteCommand(commandId: "test", description: "test") { _ in

        }
        var newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
        newRemoteCommand = RemoteCommand(commandId: "test2", description: "test") { _ in

        }
        newConfig.remoteCommands = nil
        newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
    }

    func testUpdateReservedCommandsWhenAlreadyAdded() {
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        module.reservedCommandsAdded = true
        XCTAssertEqual(remoteCommandsManager.addCount, 0)
        XCTAssertEqual(remoteCommandsManager.removeCommandWithIdCount, 0)
    }

    func testInitializeWithDefaultCommands() {
        config.remoteHTTPCommandDisabled = false
        module = RemoteCommandsModule(config: config, delegate: self, completion: { _ in })
        XCTAssertEqual(module.remoteCommands?.commands.count, 1)
    }

    func testInitializeDefaultCommandsDisabled() {
        config.remoteHTTPCommandDisabled = true
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        XCTAssertEqual(module.remoteCommands?.commands.count, 0)
    }

}

extension RemoteCommandsModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        if let _ = request as? TealiumRemoteCommandRequest {
            self.processExpectation?.fulfill()
        }
    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }
}
