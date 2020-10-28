//
//  MockLocationModuleDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class MockLocationModuleDelegate: ModuleDelegate {

    var trackRequest: TealiumTrackRequest?
    var asyncExpectation: XCTestExpectation?

    func requestTrack(_ track: TealiumTrackRequest) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockLocationDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        trackRequest = track
        expectation.fulfill()
    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
