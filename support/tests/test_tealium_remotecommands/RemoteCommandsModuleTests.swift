//
//  RemoteCommandsModuleTests.swift
//  tealium-swift
//
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
    let remoteCommand = MockWebViewRemoteCommand()
    let jsonRemoteCommand = MockJSONRemoteCommand()
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

        XCTAssertTrue((remoteCommands.webviewCommands.isEmpty), "Unexpected number of reserve commands found: \(String(describing: module.remoteCommands?.webviewCommands))")
    }

    //Integration Test
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
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 1)
        var newRemoteCommand = RemoteCommand(commandId: "test", description: "test") { _ in

        }
        let newJSONCommand = RemoteCommand(commandId: "jsontest", description: "json test", type: .remote(url: "test"), completion: { _ in })
        var newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        newConfig.addRemoteCommand(newJSONCommand)
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 1)
        newRemoteCommand = RemoteCommand(commandId: "test2", description: "test") { _ in

        }
        newConfig.remoteCommands = nil
        newConfig = config.copy
        newConfig.addRemoteCommand(newRemoteCommand)
        newConfig.addRemoteCommand(newJSONCommand)
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 1)
        //XCTAssertEqual(module.remoteCommands?.jsonCommands.count, 1)

        newConfig.remoteCommands = nil
        newConfig.addRemoteCommand(newRemoteCommand)
        newConfig.addRemoteCommand(newJSONCommand)
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 1)
        //XCTAssertEqual(module.remoteCommands?.jsonCommands.count, 1)
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
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 1)
    }

    func testInitializeDefaultCommandsDisabled() {
        config.remoteHTTPCommandDisabled = true
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        XCTAssertEqual(module.remoteCommands?.webviewCommands.count, 0)
    }

    func testDynamicTrackWithWebViewCommand() {
        let request = TealiumRemoteCommandRequest(data: ["com.tealium.tagmanagement.urlrequest": "data"])
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        module.remoteCommands?.add(remoteCommand)
        module.dynamicTrack(request, completion: nil)
        XCTAssertEqual(remoteCommandsManager.triggerCount, 1)
        XCTAssertEqual(remoteCommandsManager.refreshCount, 0)
    }

    func testDynamicTrackWithJSONCommand() {
        let request = TealiumRemoteAPIRequest(trackRequest: TealiumTrackRequest(data: ["test": "data"]))
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: remoteCommandsManager)
        module.dynamicTrack(request, completion: nil)
        XCTAssertEqual(remoteCommandsManager.triggerCount, 1)
        XCTAssertEqual(remoteCommandsManager.refreshCount, 1)
    }

    func testDynamicTrackForJSONCommandWhenManagerNil() {
        let request = TealiumRemoteAPIRequest(trackRequest: TealiumTrackRequest(data: ["test": "data"]))
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: nil)
        module.dynamicTrack(request, completion: nil)
        XCTAssertEqual(remoteCommandsManager.triggerCount, 0)
        XCTAssertEqual(remoteCommandsManager.refreshCount, 0)
    }

    func testDynamicTrackForJSONCommandWhenSomeConfigPartsNil() {
        let request = TealiumRemoteAPIRequest(trackRequest: TealiumTrackRequest(data: ["test": "data"]))
        let jsonCommandConfig = RemoteCommandConfig(config: ["hello": "world"], mappings: ["map": "this"], apiCommands: ["command": "this"], commandName: nil, commandURL: nil)
        let mockJSONCommand = MockJSONRemoteCommand(config: jsonCommandConfig)
        let mockRemoteCommandMgr = MockRemoteCommandsManager(jsonCommand: mockJSONCommand)
        module = RemoteCommandsModule(config: config, delegate: self, remoteCommands: mockRemoteCommandMgr)
        module.dynamicTrack(request, completion: nil)
        XCTAssertEqual(remoteCommandsManager.triggerCount, 0)
        XCTAssertEqual(remoteCommandsManager.refreshCount, 0)
    }

}

extension RemoteCommandsModuleTests: ModuleDelegate {
    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {
        if let _ = request as? TealiumRemoteCommandRequest {
            self.processExpectation?.fulfill()
        }
    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

}
