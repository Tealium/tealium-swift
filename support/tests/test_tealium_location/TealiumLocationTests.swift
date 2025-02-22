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
        locationModule = createModule(with: config)
    }

    // MARK: Tealium Location Tests
    func testDesiredAccuracyIsSet() {
        config.desiredAccuracy = .bestForNavigation
        let locationManager = TealiumLocationManager(config: config)
        XCTAssertEqual(locationManager.locationManager.desiredAccuracy, kCLLocationAccuracyBestForNavigation)
    }
    
    func testEnabledBackgroundLocationIsSet() {
        let locationManager1 = TealiumLocationManager(config: config)
        XCTAssertFalse(locationManager1.locationManager.allowsBackgroundLocationUpdates) // default false
        config.enableBackgroundLocation = true
        let locationManager2 = TealiumLocationManager(config: config)
        XCTAssertTrue(locationManager2.locationManager.allowsBackgroundLocationUpdates)
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
        onLocationReady(location: tealiumLocation) {
            tealiumLocation.startLocationUpdates()
            XCTAssertEqual(1, self.locationManager.startUpdatingLocationCount)
        }
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
        onLocationReady(location: tealiumLocation) {
            XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
        }
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
        onLocationReady(location: tealiumLocation) {
            let expected = tealiumLocation.createdGeofences
            XCTAssertEqual(expected, ["Tealium_Reading", "Tealium_San_Diego"])
        }
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

        onLocationReady(location: tealiumLocation) {
            XCTAssertEqual(tealiumLocation.createdGeofences!.count, 1)
            XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading"])
        }
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

        onLocationReady(location: tealiumLocation) {
            XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
        }
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

        onLocationReady(location: tealiumLocation) {
            let regions = tealiumLocation.geofences.regions
            tealiumLocation.startMonitoring(regions)

            XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[0]), true)
            XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[1]), true)
        }
    }
    
    func onLocationReady(location: TealiumLocationManager, completion: @escaping () -> ()) {
        let exp = expectation(description: "wait ready")
        location.onReady.subscribeOnce {
            completion()
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
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

        onLocationReady(location: tealiumLocation) {
            tealiumLocation.startMonitoring([region])
            XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(region), true)
        }
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
        let json = """
        {
        "name": "testRegion",
        "latitude": 37.3317,
        "longitude": -122.0325086,
        "radius": 100,
        "trigger_on_enter": true,
        "trigger_on_exit": true
        }
        """
        let data = json.data(using: .utf8)
        let geofence = try! JSONDecoder().decode(Geofence.self, from: data!)
        tealiumLocation.geofences = [geofence]
        
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

            let expected: [String: Any] = [TealiumDataKey.event: LocationKey.entered,
                                           TealiumDataKey.locationAccuracy: "high",
                                           TealiumDataKey.geofenceName: "testRegion",
                                           TealiumDataKey.geofenceTransition: LocationKey.entered,
                                           TealiumDataKey.deviceLatitude: "37.3317",
                                           TealiumDataKey.deviceLongitude: "-122.0325086",
                                           TealiumDataKey.locationTimestamp: "2020-01-15 06:31:00 +0000",
                                           TealiumDataKey.locationSpeed: "40.0",
                                           TealiumDataKey.locationAccuracyExtended: "reduced"]
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
        let json = """
        {
        "name": "testRegion",
        "latitude": 37.3317,
        "longitude": -122.0325086,
        "radius": 100,
        "trigger_on_enter": true,
        "trigger_on_exit": true
        }
        """
        let data = json.data(using: .utf8)
        let geofence = try! JSONDecoder().decode(Geofence.self, from: data!)
        tealiumLocation.geofences = [geofence]

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

            let expected: [String: Any] = [TealiumDataKey.event: LocationKey.exited,
                                           TealiumDataKey.geofenceName: "testRegion",
                                           TealiumDataKey.geofenceTransition: LocationKey.exited]
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

        let data: [String: Any] = [TealiumDataKey.geofenceName: "Tealium_San_Diego",
                                   TealiumDataKey.geofenceTransition: LocationKey.entered,
                                   TealiumDataKey.event: LocationKey.entered]

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
    
    func testOnlyMonitoredGeofenceTriggersEnterEvent() {
        let expect = expectation(description: "testOnlyMonitoredGeofenceTriggersEnterEvent")
        expect.isInverted = true
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

        let tealiumLocation = TealiumLocationManager(config: config, locationDelegate: locationModule,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion(center: CLLocationCoordinate2DMake(51.4610304, -0.9707625), radius: CLLocationDistance(100), identifier: "test_region")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        tealiumLocation.sendGeofenceTrackingEvent(region: region, triggeredTransition: "geofence_entered")
        
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard mockModuleDelegate.trackRequest == nil else {
                XCTFail("Should not have triggered a track call; region wasn't being monitored")
                return
            }
        }
    }

    func testDidExitGeofence() {
        let expect = expectation(description: "testDidExitGeofence")
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

        let data: [String: Any] = [TealiumDataKey.geofenceName: "Tealium_San_Diego",
                                   TealiumDataKey.geofenceTransition: LocationKey.exited,
                                   TealiumDataKey.event: LocationKey.exited]

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

        onLocationReady(location: tealiumLocation) {
            tealiumLocation.startMonitoring([region1, region2])
            XCTAssertEqual(2, self.locationManager.startMonitoringCount)

            tealiumLocation.startMonitoring(geofence: region3)
            XCTAssertEqual(3, self.locationManager.startMonitoringCount)
        }
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
        
        onLocationReady(location: tealiumLocation) {
            tealiumLocation.lastLocation = location
            
            let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")
            
            let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")
            
            let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion3")
            
            tealiumLocation.startMonitoring([region1, region2, region3])

            tealiumLocation.stopMonitoring([region1, region2])
            XCTAssertEqual(2, self.locationManager.stopMonitoringCount)

            tealiumLocation.stopMonitoring(geofence: region3)
            XCTAssertEqual(3, self.locationManager.stopMonitoringCount)
        }
    }

    func testMonitoredGeofences() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        onLocationReady(location: tealiumLocation) {
            tealiumLocation.startMonitoring([region])

            XCTAssertEqual(["Good_Geofence"], tealiumLocation.monitoredGeofences!)
        }
    }

    func testClearMonitoredGeofences() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let json = """
        {
        "name": "Good_Geofence",
        "latitude": 0.0,
        "longitude": 0.0,
        "radius": 100,
        "trigger_on_enter": true,
        "trigger_on_exit": true
        }
        """
        let data = json.data(using: .utf8)
        let geofence = try! JSONDecoder().decode(Geofence.self, from: data!)
        tealiumLocation.geofences.append(geofence)
        
        let json2 = """
        {
        "name": "Another_Good_Geofence",
        "latitude": 10.0,
        "longitude": 10.0,
        "radius": 100,
        "trigger_on_enter": true,
        "trigger_on_exit": true
        }
        """
        let data2 = json2.data(using: .utf8)
        let geofence2 = try! JSONDecoder().decode(Geofence.self, from: data2!)
        tealiumLocation.geofences.append(geofence2)
        
        let region1 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        let region2 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), radius: CLLocationDistance(200.0), identifier: "Another_Good_Geofence")

        tealiumLocation.startMonitoring([region1, region2])
        tealiumLocation.clearMonitoredGeofences()

        XCTAssertEqual(2, locationManager.stopMonitoringCount)
        XCTAssertEqual(0, tealiumLocation.monitoredGeofences!.count)
    }
    
    func testClearMonitoredGeofencesOnlyClearsOwnGeofences() {
        let tealiumLocation = TealiumLocationManager(config: config,
                                                     locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region1 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        let region2 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), radius: CLLocationDistance(200.0), identifier: "Another_Good_Geofence")
    
        let json = """
        {
        "name": "Good_Geofence",
        "latitude": 0.0,
        "longitude": 0.0,
        "radius": 100,
        "trigger_on_enter": true,
        "trigger_on_exit": true
        }
        """
        let data = json.data(using: .utf8)
        let geofence = try! JSONDecoder().decode(Geofence.self, from: data!)
        tealiumLocation.geofences = [geofence]
        
        tealiumLocation.startMonitoring([region1, region2])
        tealiumLocation.clearMonitoredGeofences()

        XCTAssertEqual(1, locationManager.stopMonitoringCount)
        XCTAssertEqual(1, tealiumLocation.monitoredGeofences!.count)
        XCTAssertEqual(tealiumLocation.monitoredGeofences!.first!, "Another_Good_Geofence")
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
            locationModule?.tealiumLocationManager = mockTealiumLocationManager
            _ = locationModule?.isFullAccuracy
            XCTAssertEqual(self.mockTealiumLocationManager.isFullAccuracyCallCount, 1)
        }
    }

    func testModuleCreatedGeofences() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.createdGeofences
        XCTAssertEqual(self.mockTealiumLocationManager.createdGeofencesCallCount, 1)
    }

    func testModuleGetCreatedGeofences() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.getCreatedGeofences(completion: { _ in })
        XCTAssertEqual(self.mockTealiumLocationManager.createdGeofencesCallCount, 1)
    }

    func testModuleLastLocation() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.lastLocation
        XCTAssertEqual(self.mockTealiumLocationManager.lastLocationCallCount, 1)
    }

    func testModuleGetLastLocation() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.getLastLocation(completion: { _ in })
        XCTAssertEqual(self.mockTealiumLocationManager.lastLocationCallCount, 1)
    }

    func testModuleMonitoredGeofences() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.monitoredGeofences
        XCTAssertEqual(self.mockTealiumLocationManager.monitoredGeofencesCallCount, 1)
    }

    func testModuleGetMonitoredGeofences() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        _ = locationModule?.getMonitoredGeofences(completion: { _ in })
        XCTAssertEqual(self.mockTealiumLocationManager.monitoredGeofencesCallCount, 1)
    }

    func testModuleClearMonitoredGeofences() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.clearMonitoredGeofences()
        XCTAssertEqual(self.mockTealiumLocationManager.clearMonitoredGeofencesCallCount, 1)
    }

    func testModuleDisable() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.disable()
        XCTAssertEqual(self.mockTealiumLocationManager.disableCallCount, 1)
    }

    func testModuleRequestAuthorization() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.requestAuthorization()
        XCTAssertEqual(self.mockTealiumLocationManager.requestAuthorizationCallCount, 1)
    }

    func testModuleRequestTemporaryFullAccuracyAuthorization() {
        if #available(iOS 14, *) {
            let purpose = "Because I said so"
            locationModule?.tealiumLocationManager = mockTealiumLocationManager
            locationModule?.requestTemporaryFullAccuracyAuthorization(purposeKey: purpose)
            XCTAssertEqual(self.mockTealiumLocationManager.requestTemporaryFullAccuracyAuthorizationCallCount, 1)
        }
    }

    func testModuleSendGeofenceTrackingEvent() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.sendGeofenceTrackingEvent(region: CLRegion(), triggeredTransition: "test")
        XCTAssertEqual(self.mockTealiumLocationManager.sendGeofenceTrackingEventCallCount, 1)
    }

    func testModuleStartLocationUpdates() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.startLocationUpdates()
        XCTAssertEqual(self.mockTealiumLocationManager.startLocationUpdatesCallCount, 1)
    }

    func testModuleStartMonitoring() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")
        locationModule?.startMonitoring(geofences: [region])
        XCTAssertEqual(self.mockTealiumLocationManager.startMonitoringCallCount, 1)
    }

    func testModuleStopLocationUpdates() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        locationModule?.stopLocationUpdates()
        XCTAssertEqual(self.mockTealiumLocationManager.stopLocationUpdatesCallCount, 1)
    }

    func testModuleStopMonitoring() {
        locationModule?.tealiumLocationManager = mockTealiumLocationManager
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")
        locationModule?.stopMonitoring(geofences: [region])
        XCTAssertEqual(self.mockTealiumLocationManager.stopMonitoringCallCount, 1)
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
        let expected: [String: Any] = [TealiumDataKey.event: LocationKey.entered,
                                       TealiumDataKey.locationAccuracy: "reduced",
                                       TealiumDataKey.geofenceName: "testRegion",
                                       TealiumDataKey.geofenceTransition: LocationKey.entered,
                                       TealiumDataKey.deviceLatitude: "37.3317",
                                       TealiumDataKey.deviceLongitude: "-122.0325086",
                                       TealiumDataKey.locationTimestamp: timestamp,
                                       TealiumDataKey.locationSpeed: "40.0"]
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
        let expected: [String: Any] = [TealiumDataKey.event: LocationKey.exited,
                                       TealiumDataKey.geofenceName: "testRegion",
                                       TealiumDataKey.geofenceTransition: LocationKey.exited]
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
