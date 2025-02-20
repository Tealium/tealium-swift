//
//  GeofenceProviderTests.swift
//  TealiumLocationTests-iOS
//
//  Created by Enrico Zannini on 20/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumLocation

class MockProviderDelegate: ItemsProviderDelegate {
    @ToAnyObservable<TealiumReplaySubject<[Geofence]>>(TealiumReplaySubject<[Geofence]>())
    var geofences: TealiumObservable<[Geofence]>

    func didLoadItems(_ geofences: [Geofence]) {
        _geofences.publish(geofences)
    }
}

final class GeofenceProviderTests: XCTestCase {
    typealias GeofenceFile = ItemsFile<Geofence>
    let config = TealiumConfig(account: "test", profile: "test", environment: "dev")
    let urlSession = MockURLSession()
    lazy var diskStorage = MockTealiumDiskStorage()
    lazy var provider = GeofenceProvider(config: config,
                                         bundle: Bundle(for: type(of: self)),
                                         urlSession: urlSession,
                                         diskStorage: diskStorage)
    static let geofences = [
        Geofence(name: "123", latitude: 12, longitude: 12, radius: 12, triggerOnEnter: true, triggerOnExit: true),
        Geofence(name: "456", latitude: 45, longitude: 45, radius: 45, triggerOnEnter: false, triggerOnExit: false)
    ]

    func testGeofencesLoaded() {
        let geofencesLoaded = expectation(description: "geofences loaded")

        urlSession.result = .success(with: Self.geofences, statusCode: 200)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, Self.geofences)
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testInvalidGeofencesAreFilteredOut() {
        let geofencesLoaded = expectation(description: "geofences loaded")
        let invalidGeofences = [
            Geofence(name: "123", latitude: 91, longitude: 12, radius: 12, triggerOnEnter: true, triggerOnExit: true),
            Geofence(name: "456", latitude: 45, longitude: 181, radius: 45, triggerOnEnter: false, triggerOnExit: false),
            Geofence(name: "789", latitude: 45, longitude: 181, radius: -1, triggerOnEnter: true, triggerOnExit: false)
        ]
        urlSession.result = .success(with: Self.geofences + invalidGeofences, statusCode: 200)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, Self.geofences)
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testGeofencesLoadedEmptyWhenRequestFails() {
        let geofencesLoaded = expectation(description: "geofences loaded")

        urlSession.result = .success(withData: Data(), statusCode: 404)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, [])
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testGeofencesLoadedFromCacheWhenAvailable() {
        let geofencesLoaded = expectation(description: "geofences loaded")
        // 429 causes retries so won't report immediately in the refresher
        urlSession.result = .success(withData: Data(), statusCode: 429)
        let file = GeofenceFile(etag: nil, items: Self.geofences)
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: GeofenceFile.self), file)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, Self.geofences)
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    // Test cached + remote success
    func testGeofencesLoadedFromCacheWhenAvailableAndUpdatedFromRemote() {
        let geofencesLoaded = expectation(description: "geofences loaded")
        geofencesLoaded.expectedFulfillmentCount = 2
        urlSession.result = .success(with: Self.geofences, statusCode: 200)
        let file = GeofenceFile(etag: nil, items: [])
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: GeofenceFile.self), file)
        let delegate = MockProviderDelegate()
        var count = 0
        delegate.$geofences.subscribe { result in
            if count == 0 {
                XCTAssertEqual(result, [])
            } else {
                XCTAssertEqual(result, Self.geofences)
            }
            count += 1
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testGeofencesLoadedFromCacheWhenAvailableAndFailsFromRemote() {
        let geofencesLoaded = expectation(description: "geofences loaded")
        urlSession.result = .success(withData: Data(), statusCode: 404)
        let file = GeofenceFile(etag: nil, items: Self.geofences)
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: GeofenceFile.self), file)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, Self.geofences)
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testLocalGeofencesFile() {
        let geofencesLoaded = expectation(description: "geofences loaded")
        config.geofenceFileName = "geofences"
        let expected = [
            Geofence(name: "Tealium_Reading", latitude: 51.4610304, longitude: -0.9707625, radius: 100, triggerOnEnter: true, triggerOnExit: true),
            Geofence(name: "Tealium_San_Diego", latitude: 32.84173, longitude: -117.02026, radius: 100, triggerOnEnter: true, triggerOnExit: true)
        ]
        urlSession.result = .success(with: Self.geofences, statusCode: 200)
        let delegate = MockProviderDelegate()
        delegate.$geofences.subscribe { result in
            XCTAssertEqual(result, expected)
            geofencesLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }
}
