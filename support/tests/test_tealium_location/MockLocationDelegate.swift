//
//  MockLocationDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumLocation
import TealiumCore
import XCTest

class MockLocationDelegate: LocationDelegate {

    var locationData: [String: Any]?
    let didEnter: ([String: Any]) -> Void
    let didExit: ([String: Any]) -> Void
    init(didEnter: @escaping ([String: Any]) -> Void = { _ in }, didExit: @escaping ([String: Any]) -> Void = { _ in }) {
        self.didExit = didExit
        self.didEnter = didEnter
    }

    func didEnterGeofence(_ data: [String: Any]) {
        locationData = data
        didEnter(data)
    }

    func didExitGeofence(_ data: [String: Any]) {
        locationData = data
        didExit(data)
        let expected: [String: Any] = [TealiumDataKey.event: LocationKey.exited,
                                       TealiumDataKey.geofenceName: "testRegion",
                                       TealiumDataKey.geofenceTransition: LocationKey.exited]
        XCTAssertEqual(NSDictionary(dictionary: data), NSDictionary(dictionary: expected))
    }

}
