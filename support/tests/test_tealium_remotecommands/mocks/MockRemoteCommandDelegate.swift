//
//  MockRemoteCommandDelegate.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumRemoteCommands
import XCTest

class MockRemoteCommandDelegate: RemoteCommandDelegate {

    var remoteCommandResult: RemoteCommandResponseProtocol?
    var asyncExpectation: XCTestExpectation?

    func remoteCommandRequestsExecution(_ command: RemoteCommandProtocol,
                                               response: RemoteCommandResponseProtocol) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockRemoteCommandDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        remoteCommandResult = response
        expectation.fulfill()
    }

}
