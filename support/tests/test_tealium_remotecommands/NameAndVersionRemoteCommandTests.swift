//
//  NameAndVersionRemoteCommandTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Enrico Zannini on 26/04/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
import TealiumRemoteCommands

class NameAndVersionRemoteCommand: RemoteCommand {
    
    private let _version: String?
    private let _name: String?
    
    override var version: String? {
        return _version ?? super.version
    }
    override var name: String {
        return _name ?? super.name
    }
    
    init(commandId: String,
                description: String?,
                type: RemoteCommandType = .webview,
                name: String? = nil,
                version: String? = nil,
                completion : @escaping (_ response: RemoteCommandResponseProtocol) -> Void) {
        self._name = name
        self._version = version
        super.init(commandId: commandId, description: description, type: type, completion: completion)
    }
}

class SomeRemoteCommand: RemoteCommand {
    override var name: String {
        return "constantName"
    }
}

class NameAndVersionRemoteCommandTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNameAndVersion() throws {
        let testName = "testName"
        let testVersion = "X.Y.Z"
        let command = NameAndVersionRemoteCommand(commandId: "commandId", description: "", type: .webview, name: testName, version: testVersion, completion: { response in
            print(response)
        })
        XCTAssertEqual(testName, command.name)
        XCTAssertEqual(testVersion, command.version)
    }
    
    func testDerivateRemoteCommandName() throws {
        let command = SomeRemoteCommand(commandId: "commandId", description: "", type: .webview, completion: { response in
            print(response)
        })
        XCTAssertEqual("constantName", command.name)
    }
}
