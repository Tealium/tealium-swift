//
//  MockLocationDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumLocation
import XCTest

class MockLocationDelegate: LocationDelegate {

    var locationData: [String: Any]?
    var asyncExpectation: XCTestExpectation?

    func didEnterGeofence(_ data: [String: Any]) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockLocationDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        locationData = data
        expectation.fulfill()
    }

    func didExitGeofence(_ data: [String: Any]) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockLocationDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        locationData = data
        expectation.fulfill()
    }

}
