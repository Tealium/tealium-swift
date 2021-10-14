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
            XCTFail("MockConsentDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        if asyncExpectation?.description == "testConsentGrantedTriggersDequeueRequest" {
            return
        }
        trackInfo = track.trackDictionary
        expectation.fulfill()
        asyncExpectation = XCTestExpectation(description: "\(expectation.description)1")
    }

    func requestDequeue(reason: String) {
        guard asyncExpectation?.description == "testConsentGrantedTriggersDequeueRequest" else {
            return
        }
        guard reason == "Consent Granted" else {
            XCTFail()
            return
        }
        asyncExpectation?.fulfill()
    }

    func processRemoteCommandRequest(_ request: TealiumRequest) { }

}
