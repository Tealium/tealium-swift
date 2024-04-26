//
//  ErrorCooldownTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 09/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

final class ErrorCooldownTests: XCTestCase {
    let errorCooldown = ErrorCooldown(baseInterval: 10, maxInterval: 50)!

    func testStartsNotInCooldown() {
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testGoesInCooldownAfterError() {
        errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testCooldownEndsAfterErrorBaseInterval() {
        errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
    }

    func testCooldownIncreasesAfterNewErrors() {
        errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()))
        errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-21)))
    }

    func testCooldownCantBeOverMaxInterval() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
    }

    func testCooldownIsResetOnSuccessEvent() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
        errorCooldown.newCooldownEvent(error: nil)
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date()))
    }

    func testCooldownIsOnBaseValueAfterBeingReset() {
        for _ in 0..<7 {
            errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        }
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-49)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-51)))
        errorCooldown.newCooldownEvent(error: nil)
        errorCooldown.newCooldownEvent(error: HTTPError.unknown)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-9)))
        XCTAssertFalse(errorCooldown.isInCooldown(lastFetch: Date().addingTimeInterval(-11)))
    }
    
    func testInitializationFailsWithoutBaseInterval() {
        let errorCooldown = ErrorCooldown(baseInterval: nil, maxInterval: 50)
        XCTAssertNil(errorCooldown)
    }
}
