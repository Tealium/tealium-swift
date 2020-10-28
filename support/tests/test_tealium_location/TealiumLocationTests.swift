//
//  TealiumLocationTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import CoreLocation
@testable import TealiumCore
@testable import TealiumLocation
import XCTest

class TealiumLocationTests: XCTestCase {

    static var expectations = [XCTestExpectation]()
    var locationManager: MockLocationManager!
    var config: TealiumConfig!
    var locationModule: LocationModule?
    var mockTealiumLocationManager = MockTealiumLocaitonManager()
    
    func createModule(with config: TealiumConfig? = nil, delegate: ModuleDelegate? = nil) -> LocationModule {
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig())
        return LocationModule(context: context, delegate: delegate ?? self, diskStorage: MockLocationDiskStorage(config: config ?? TestTealiumHelper().getConfig()), completion: { _ in })
    }

    override func setUp() {
        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        guard let locationManager = MockLocationManager(config: config, enableServices: true, delegateClass: nil) else {
            XCTFail("MockLocationManager did not init properly - shouldn't happen")
            return
        }

        self.locationManager = locationManager
        TealiumLocationTests.expectations = [XCTestExpectation]()
        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        locationModule = createModule(with: config)
    }

    override func tearDown() {
        TealiumLocationTests.expectations = [XCTestExpectation]()
    }

    // MARK: Tealium Location Tests
    func testDesiredAccuracyIsSet() {
        config.desiredAccuracy = .bestForNavigation
        let locationManager = TealiumLocationManager(config: config)
        XCTAssertEqual(locationManager.locationManager.desiredAccuracy, kCLLocationAccuracyBestForNavigation)
    }

    func testLocationAccuracyEnum() {
        if #available(iOS 14, *) {
            let cases: [LocationAccuracy] = [.best, .bestForNavigation, .nearestHundredMeters, .nearestTenMeters, .reduced, .withinOneKilometer, .withinThreeKilometers]
            let expected: [CLLocationAccuracy] = [kCLLocationAccuracyBest, kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyHundredMeters,
                                                  kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyKilometer, kCLLocationAccuracyThreeKilometers, kCLLocationAccuracyReduced]

            let actual: [CLLocationAccuracy] = cases.map { CLLocationAccuracy($0) }

            XCTAssertEqual(actual.sorted(), expected.sorted())
        }
    }

    func testIsAuthorizedCallsAuthorizationStatus() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        _ = tealiumLocation.isAuthorized
        XCTAssertTrue( MockLocationManager.authorizationStatusCount > 0)
    }

    func testIsFullAccuracyCallsAccuracyAuthorization() {
        if #available(iOS 14, *) {
            let tealiumLocation = TealiumLocationManager(config: config,
                                                         locationManager: locationManager)

            locationManager.delegate = tealiumLocation
            _ = tealiumLocation.isFullAccuracy
            XCTAssertEqual(1, locationManager.accuracyAuthorizationCallCount)
        }
    }

    func testRequestAuthorizationCallsRequestWhenInUseAuthByDefault() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        tealiumLocation.requestAuthorization()
        XCTAssertEqual(1, locationManager.requestWhenInUseAuthorizationCount)
    }

    func testRequestTemporaryFullAccuracyCallsLocationManager() {
        if #available(iOS 14, *) {
            let tealiumLocation = TealiumLocationManager(config: config,
                                                         locationManager: locationManager)

            locationManager.delegate = tealiumLocation
            tealiumLocation.requestTemporaryFullAccuracyAuthorization(purposeKey: "because")
            XCTAssertEqual(1, locationManager.requestTemporaryFullAccuracyAuthorizationCount)
        }
    }

    func testRequestTemporaryFullAccuracyDoesNotRunIfLocationNotEnabled() {
        if #available(iOS 14, *) {
            let locationMgrServicesNotEnabled = MockLocationManager(config: config, delegateClass: nil)
            let tealiumLocation = TealiumLocationManager(config: config,
                                                         locationManager: locationMgrServicesNotEnabled!)

            locationMgrServicesNotEnabled?.delegate = tealiumLocation
            tealiumLocation.requestTemporaryFullAccuracyAuthorization(purposeKey: "because")
            XCTAssertEqual(0, locationManager.requestTemporaryFullAccuracyAuthorizationCount)
        }
    }

    func testStartUpdatingLocationChangesWhenDefault() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        tealiumLocation.startLocationUpdates()
        XCTAssertEqual(1, locationManager.startUpdatingLocationCount)
    }

    func testStartUpdatingLocationDoesntRunWhenLocationNotAuthorized() {
        let locationMgrServicesNotAuthorized = MockLocationManager(config: config, delegateClass: nil)
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationMgrServicesNotAuthorized!)

        locationMgrServicesNotAuthorized?.delegate = tealiumLocation
        tealiumLocation.startLocationUpdates()
        XCTAssertEqual(0, locationManager.startUpdatingLocationCount)
    }

    func testLastLocationNilUponInit() throws {
        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: self,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        XCTAssertNil(tealiumLocation.lastLocation)
    }

    func testLastLocationReturnsNilWhenLocationNotEnabled() {
        let locationMgrServicesNotEnabled = MockLocationManager(config: config, delegateClass: nil)
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationMgrServicesNotEnabled!)

        locationMgrServicesNotEnabled?.delegate = tealiumLocation
        XCTAssertNil(tealiumLocation.lastLocation)
    }

    func testMonitoredGeofencesReturnsNilWhenLocationServicesNotAuthorized() {
        let locationMgrServicesNotAuthorized = MockLocationManager(config: config, delegateClass: nil)
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationMgrServicesNotAuthorized!)

        locationMgrServicesNotAuthorized?.delegate = tealiumLocation
        XCTAssertNil(tealiumLocation.monitoredGeofences)
    }

    func testCreatedGeofencesReturnsNilWhenLocationServicesNotAuthorized() {
        let locationMgrServicesNotAuthorized = MockLocationManager(config: config, delegateClass: nil)
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationMgrServicesNotAuthorized!)

        locationMgrServicesNotAuthorized?.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")

        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")

        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.startMonitoring([region1, region2])

        XCTAssertNil(tealiumLocation.createdGeofences)
    }

    func testStopMonitoringDoesntRunWhenGeofencesEmpty() {
        let emptyGeofences = [CLCircularRegion]()
        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: self,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        tealiumLocation.stopMonitoring(emptyGeofences)
        XCTAssertEqual(0, locationManager.stopMonitoringCount)
    }

    func testValidUrl() {
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        let tealiumLocation = TealiumLocationManager(config: config, locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidUrl() {
        config.geofenceUrl = "thisIsNotAValidURL"
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidAsset() {
        config.geofenceFileName = "validGeofences"
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     bundle: Bundle(for: type(of: self)),
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        let expected = tealiumLocation.createdGeofences
        XCTAssertEqual(expected, ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidAsset() {
        config.geofenceFileName = "invalidGeofences"
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     bundle: Bundle(for: type(of: self)),
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidAndInvalidAsset() {
        config.geofenceFileName = "validAndInvalidGeofences"
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     bundle: Bundle(for: type(of: self)),
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 1)
        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading"])
    }

    func testNonExistentAsset() {
        config.geofenceFileName = "SomeJsonFileThatDoesntExist"
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     bundle: Bundle(for: type(of: self)),
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidConfig() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidConfig() {
        config = TealiumConfig(account: "IDontExist", profile: "IDontExist", environment: "IDontExist")
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.geofences.count, 0)
        XCTAssert(tealiumLocation.createdGeofences!.isEmpty)
    }

    func testInitializelocationManagerValidDistance() {
        config.updateDistance = 100.0
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.locationManager.distanceFilter, 100.0)
    }

    func testStartMonitoringGeofencesGoodArray() {
        config.geofenceFileName = "validGeofences.json"
        let bundle = Bundle(for: type(of: self))
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     bundle: bundle,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let regions = tealiumLocation.geofences.regions
        tealiumLocation.startMonitoring(regions)

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[0]), true)
        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[1]), true)
    }

    func testStartMonitoringGeofencesBadArray() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.startMonitoring([CLCircularRegion]())

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.count, 0)
    }

    func testStartMonitoringGeofencesGoodRegion() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        tealiumLocation.startMonitoring([region])

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(region), true)
    }

    func testStopLocationUpdates() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)
        locationManager.delegate = tealiumLocation
        tealiumLocation.stopLocationUpdates()
        XCTAssert(MockLocationManager.authorizationStatusCount > 0)
        XCTAssertEqual(1, locationManager.stopUpdatingLocationCount)
    }

    func testSendGeofenceTrackingEventEntered() {
        let expect = expectation(description: "testSendGeofenceTrackingEventEntered")
        TealiumLocationTests.expectations.append(expect)

        NSTimeZone.default = TimeZone(abbreviation: "PST")!

        let mockLocationDelegate = MockLocationDelegate()
        mockLocationDelegate.asyncExpectation = expect

        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: mockLocationDelegate,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.entered)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockLocationDelegate.locationData else {
                XCTFail("Expected delegate to be called")
                return
            }

            let expected: [String: Any] = [TealiumKey.event: LocationKey.entered,
                                           LocationKey.accuracy: "high",
                                           LocationKey.geofenceName: "testRegion",
                                           LocationKey.geofenceTransition: LocationKey.entered,
                                           LocationKey.deviceLatitude: "37.3317",
                                           LocationKey.deviceLongitude: "-122.0325086",
                                           LocationKey.timestamp: "2020-01-15 06:31:00 +0000",
                                           LocationKey.speed: "40.0",
                                           LocationKey.accuracyExtended: "reduced"]
            XCTAssertEqual(expected.keys.sorted(), result.keys.sorted())
            result.forEach {
                guard let value = $0.value as? String,
                      let expected = expected[$0.key] as? String else { return }
                XCTAssertEqual(expected, value)
            }
        }
    }

    func testSendGeofenceTrackingEventExited() {
        let expect = expectation(description: "testSendGeofenceTrackingEventExited")
        TealiumLocationTests.expectations.append(expect)

        let mockLocationDelegate = MockLocationDelegate()
        mockLocationDelegate.asyncExpectation = expect

        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: mockLocationDelegate,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.exited)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockLocationDelegate.locationData else {
                XCTFail("Expected delegate to be called")
                return
            }

            let expected: [String: Any] = [TealiumKey.event: LocationKey.exited,
                                           LocationKey.geofenceName: "testRegion",
                                           LocationKey.geofenceTransition: LocationKey.exited]
            XCTAssertEqual(expected.keys, result.keys)
            result.forEach {
                guard let value = $0.value as? String,
                      let expected = expected[$0.key] as? String else { return }
                XCTAssertEqual(expected, value)
            }
        }
    }

    func testDidEnterGeofence() {
        let expect = expectation(description: "testDidEnterGeofence")
        TealiumLocationTests.expectations.append(expect)

        let mockModuleDelegate = MockLocationModuleDelegate()
        mockModuleDelegate.asyncExpectation = expect

        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        let locationModule = createModule(with: config,
                                            delegate: mockModuleDelegate)

        guard let locationManager = MockLocationManager(config: config, enableServices: true, delegateClass: nil) else {
            XCTFail("MockLocationManager did not init properly - shouldn't happen")
            return
        }
        self.locationManager = locationManager

        let data: [String: Any] = [LocationKey.geofenceName: "Tealium_San_Diego",
                                   LocationKey.geofenceTransition: LocationKey.entered,
                                   TealiumKey.event: LocationKey.entered]

        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: locationModule,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.locationDelegate?.didEnterGeofence(data)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockModuleDelegate.trackRequest else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertNotNil(result)
        }
    }

    func testDidExitGeofence() {
        let expect = expectation(description: "testDidExitGeofence")
        TealiumLocationTests.expectations.append(expect)

        let mockModuleDelegate = MockLocationModuleDelegate()
        mockModuleDelegate.asyncExpectation = expect

        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        let mockDisk = MockLocationDiskStorage(config: config)
        let locationModule = createModule(with: config,
                                          delegate: mockModuleDelegate)

        guard let locationManager = MockLocationManager(config: config, enableServices: true, delegateClass: nil) else {
            XCTFail("MockLocationManager did not init properly - shouldn't happen")
            return
        }
        self.locationManager = locationManager

        let data: [String: Any] = [LocationKey.geofenceName: "Tealium_San_Diego",
                                   LocationKey.geofenceTransition: LocationKey.exited,
                                   TealiumKey.event: LocationKey.exited]

        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: locationModule,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.locationDelegate?.didExitGeofence(data)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockModuleDelegate.trackRequest else {
                XCTFail("Expected delegate to be called")
                return
            }

            XCTAssertNotNil(result)
        }
    }

    func testLastLocationPopulated() {
        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: self,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location
        XCTAssertEqual(tealiumLocation.lastLocation, location)
    }

    func testStartMonitoring() {
        let mockLocationDelegate = MockLocationDelegate()
        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: mockLocationDelegate,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")

        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")

        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.startMonitoring([region1, region2])
        XCTAssertEqual(2, locationManager.startMonitoringCount)

        tealiumLocation.startMonitoring(geofence: region3)
        XCTAssertEqual(3, locationManager.startMonitoringCount)
    }

    func testStopMonitoring() {
        let mockLocationDelegate = MockLocationDelegate()
        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: mockLocationDelegate,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")

        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")

        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion3")

        tealiumLocation.startMonitoring([region1, region2, region3])

        tealiumLocation.stopMonitoring([region1, region2])
        XCTAssertEqual(2, locationManager.stopMonitoringCount)

        tealiumLocation.stopMonitoring(geofence: region3)
        XCTAssertEqual(3, locationManager.stopMonitoringCount)
    }

    func testMonitoredGeofences() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        tealiumLocation.startMonitoring([region])

        XCTAssertEqual(["Good_Geofence"], tealiumLocation.monitoredGeofences!)
    }

    func testClearMonitoredGeofences() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region1 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        let region2 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), radius: CLLocationDistance(200.0), identifier: "Another_Good_Geofence")

        tealiumLocation.startMonitoring([region1, region2])
        tealiumLocation.clearMonitoredGeofences()

        XCTAssertEqual(2, locationManager.stopMonitoringCount)
        XCTAssertEqual(0, tealiumLocation.monitoredGeofences!.count)
    }

    func testDisableLocationManager() {
        config.geofenceFileName = "validGeofences.json"

        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.disable()

        XCTAssertEqual(1, locationManager.stopUpdatingLocationCount)
        XCTAssertEqual(0, tealiumLocation.monitoredGeofences!.count)
        XCTAssertEqual(0, tealiumLocation.geofences.count)
    }

    // MARK: Location Module Tests

    func testLocationManagerInitializedWhileOnABackgroundThread() {
        let expect = expectation(description: "Module latest location called")
        DispatchQueue.global(qos: .background).async {
            self.locationModule = self.createModule()
            TealiumQueues.mainQueue.async {
                XCTAssertNotNil(self.locationModule?.tealiumLocationManager)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleIsAuthorized() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.isAuthorized
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.isAuthorizedCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testIsFullAccuracy() {
        if #available(iOS 14, *) {
            let expect = expectation(description: "Module latest location called")
            locationModule?.tealiumLocationManager = mockTealiumLocationManager
            _ = locationModule?.isFullAccuracy
            TealiumQueues.mainQueue.async { [weak self] in
                XCTAssertEqual(self?.mockTealiumLocationManager.isFullAccuracyCallCount, 1)
                expect.fulfill()
            }
            wait(for: [expect], timeout: 2.0)
        }
    }

    func testModuleCreatedGeofences() {
        let expect = expectation(description: "Module created geofences")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.createdGeofences
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.createdGeofencesCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleLatestLocation() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.lastLocation
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.lastLocationCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleMonitoredGeofences() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.monitoredGeofences
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.monitoredGeofencesCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleClearMonitoredGeofences() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.clearMonitoredGeofences()
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.clearMonitoredGeofencesCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleDisable() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.disable()
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.disableCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleRequestAuthorization() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.requestAuthorization()
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.requestAuthorizationCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleRequestTemporaryFullAccuracyAuthorization() {
        if #available(iOS 14, *) {
            let expect = expectation(description: "Module latest location called")
            let purpose = "Because I said so"
            locationModule?.tealiumLocationManager = mockTealiumLocationManager
            locationModule?.requestTemporaryFullAccuracyAuthorization(purposeKey: purpose)
            TealiumQueues.mainQueue.async { [weak self] in
                XCTAssertEqual(self?.mockTealiumLocationManager.requestTemporaryFullAccuracyAuthorizationCallCount, 1)
                expect.fulfill()
            }
            wait(for: [expect], timeout: 2.0)
        }
    }

    func testModuleSendGeofenceTrackingEvent() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.sendGeofenceTrackingEvent(region: CLRegion(), triggeredTransition: "test")
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.sendGeofenceTrackingEventCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleStartLocationUpdates() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.startLocationUpdates()
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.startLocationUpdatesCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleStartMonitoring() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")
        locationModule?.startMonitoring(geofences: [region])
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.startMonitoringCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleStopLocationUpdates() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.stopLocationUpdates()
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.stopLocationUpdatesCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

    func testModuleStopMonitoring() {
        let expect = expectation(description: "Module latest location called")
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")
        locationModule?.stopMonitoring(geofences: [region])
        TealiumQueues.mainQueue.async { [weak self] in
            XCTAssertEqual(self?.mockTealiumLocationManager.stopMonitoringCallCount, 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 2.0)
    }

}

extension TealiumLocationTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {
        TealiumLocationTests.expectations
            .filter {
                $0.description == "testTrackWhenEnabled" ||
                    $0.description == "testTrackWhenDisabled" ||
                    $0.description == "testDidEnterGeofence" ||
                    $0.description == "testDidExitGeofence" ||
                    $0.description == "testSendGeofenceTrackingEvent"
            }.forEach { $0.fulfill() }
    }
}

extension TealiumLocationTests: LocationDelegate {

    func didEnterGeofence(_ data: [String: Any]) {
        let tz = TimeZone.current
        var timestamp = ""
        if tz.identifier.contains("London") {
            timestamp = "2020-01-15 13:31:00 +0000"
        } else if tz.identifier.contains("Phoenix") {
            timestamp = "2020-01-15 05:31:00 +0000"
        } else {
            timestamp = "2020-01-15 06:31:00 +0000"
        }
        let expected: [String: Any] = [TealiumKey.event: LocationKey.entered,
                                       LocationKey.accuracy: "reduced",
                                       LocationKey.geofenceName: "testRegion",
                                       LocationKey.geofenceTransition: LocationKey.entered,
                                       LocationKey.deviceLatitude: "37.3317",
                                       LocationKey.deviceLongitude: "-122.0325086",
                                       LocationKey.timestamp: timestamp,
                                       LocationKey.speed: "40.0"]
        XCTAssertEqual(expected.keys.sorted(), data.keys.sorted())
        data.forEach {
            guard let value = $0.value as? String,
                  let expected = expected[$0.key] as? String else { return }
            XCTAssertEqual(expected, value)
        }
        TealiumLocationTests.expectations
            .filter { $0.description == "testSendGeofenceTrackingEventEntered" }
            .forEach { $0.fulfill() }
    }

    func didExitGeofence(_ data: [String: Any]) {
        let expected: [String: Any] = [TealiumKey.event: LocationKey.exited,
                                       LocationKey.geofenceName: "testRegion",
                                       LocationKey.geofenceTransition: LocationKey.exited]
        XCTAssertEqual(expected.keys, data.keys)
        data.forEach {
            guard let value = $0.value as? String,
                  let expected = expected[$0.key] as? String else { return }
            XCTAssertEqual(expected, value)
        }
        TealiumLocationTests.expectations
            .filter { $0.description == "testSendGeofenceTrackingEventExited" }
            .forEach { $0.fulfill() }
    }

}
