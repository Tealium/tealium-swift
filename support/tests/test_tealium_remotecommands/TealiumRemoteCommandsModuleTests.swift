//
//  TealiumRemoteCommandsModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/15/17.
//  Copyright © 2017 tealium. All rights reserved.
//

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
        
        let helper = test_tealium_helper()
        let module = TealiumRemoteCommandsModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    func testDefaultEnable() {
        
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        let module = TealiumRemoteCommandsModule(delegate: nil)
        module.enable(config: config)
        
        XCTAssertTrue(module.remoteCommands?.isEnabled == true, "Remote commands did not enable")
        XCTAssertTrue(module.remoteCommands?.commands.count == 1, "Unexpected number of reserve commands found: \(module.remoteCommands?.commands)")
    }
    
    func testDisableViaConfig() {
        
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.disableRemoteCommands()
        let module = TealiumRemoteCommandsModule(delegate: nil)
        module.enable(config: config)
        
        XCTAssertTrue(module.remoteCommands == nil, "Remote commands were unexpectedly initiazlied.")

    }
    
    func testDisableHTTPCommandsViaConfig() {
        
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   datasource: "test",
                                   optionalData: nil)
        config.disableRemoteHTTPCommand()
        let module = TealiumRemoteCommandsModule(delegate: nil)
        module.enable(config: config)
        
        XCTAssertTrue(module.remoteCommands?.isEnabled == true, "Remote commands did not enable")
        XCTAssertTrue(module.remoteCommands?.commands.count == 0, "Unexpected number of reserve commands found: \(module.remoteCommands?.commands)")
        
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
        module.enable(config: config)
        
        // Add remote command
        let testExpectation = expectation(description: "triggerTest")
        let commandId = "test"
        let remoteCommand = TealiumRemoteCommand(commandId: commandId,
                                                 description: "",
                                                 queue: nil) { (reponse) in
            
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
        let notification = Notification(name: Notification.Name.init(TealiumRemoteCommandsKey.tagmanagementNotification),
                                        object: nil,
                                        userInfo: [TealiumRemoteCommandsKey.tagmanagementNotification:urlRequest])
        module.trigger(sender: notification)
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(1 == 1, "Remote command completion block successfully triggered.")

    }
    
}
