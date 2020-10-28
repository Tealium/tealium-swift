//
//  MockConsentDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class MockConsentDelegate: ModuleDelegate {

    var trackInfo: [String: Any]?
    var asyncExpectation: XCTestExpectation?

    func requestTrack(_ track: TealiumTrackRequest) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockLocationDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        trackInfo = track.trackDictionary
        expectation.fulfill()
        asyncExpectation = XCTestExpectation(description: "\(expectation.description)1")
    }

    func requestDequeue(reason: String) { }

    func processRemoteCommandRequest(_ request: TealiumRequest) { }

}
