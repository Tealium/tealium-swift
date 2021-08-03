//
//  TealiumASIdentifierManagerTests.swift
//  TealiumAttributionTests-iOS
//
//  Created by Enrico Zannini on 03/08/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumAttribution

class TealiumASIdentifierManagerTests: XCTestCase {

    func testChangeStatus() throws {
        var idManager = TealiumASIdentifierManager.shared
        idManager.attManager = MockATTrackingManagerTrackingAuthorized()
        XCTAssertEqual(idManager.trackingAuthorizationStatus, TrackingAuthorizationDescription.authorized)
        idManager.attManager = MockATTrackingManagerTrackingDenied()
        XCTAssertEqual(idManager.trackingAuthorizationStatus, TrackingAuthorizationDescription.denied)
    }

    func testChangeAdvertisingIdentifierActive() throws {
        guard #available(iOS 14.0, *) else {
            throw XCTSkip("Unsupported iOS version")
        }
        var idManager = TealiumASIdentifierManager.shared
        idManager.attManager = MockATTrackingManagerTrackingAuthorized()
        XCTAssertEqual(idManager.isAdvertisingTrackingEnabled, "true")
        idManager.attManager = MockATTrackingManagerTrackingDenied()
        XCTAssertEqual(idManager.isAdvertisingTrackingEnabled, "false")
    }

}
