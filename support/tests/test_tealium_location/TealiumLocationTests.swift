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
    var mockManager: MockLocationManager!
    var config: TealiumConfig = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
    var locationModule: LocationModule?
    var mockTealiumLocationManager = MockTealiumLocationManager()
    lazy var locationManager = TealiumLocationManager(config: config,
                                                      bundle: Bundle(for: type(of: self)),
                                                      diskStorage: MockLocationDiskStorage(config: config),
                                                      locationManager: mockManager)

    func createModule(with config: TealiumConfig? = nil, delegate: ModuleDelegate? = nil) -> LocationModule {
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig())
        return LocationModule(context: context, delegate: delegate ?? MockLocationModuleDelegate(didRequestTrack: {_ in }), diskStorage: MockLocationDiskStorage(config: config ?? TestTealiumHelper().getConfig()), completion: { _ in })
    }

    override func setUp() {
        guard let locationManager = MockLocationManager(config: config, delegateClass: nil) else {
            XCTFail("MockLocationManager did not init properly - shouldn't happen")
            return
        }
        MockLocationManager.enableLocationServices = true
        self.mockManager = locationManager
        locationModule = createModule(with: config)
    }

    // MARK: Tealium Location Tests
    func testDesiredAccuracyIsSet() {
        config.desiredAccuracy = .bestForNavigation
        XCTAssertEqual(locationManager.locationManager.desiredAccuracy, kCLLocationAccuracyBestForNavigation)
    }
    
    func testEnabledBackgroundLocationIsSet() {
        XCTAssertFalse(locationManager.locationManager.allowsBackgroundLocationUpdates) // default false
        config.enableBackgroundLocation = true
        let locationManager2 = TealiumLocationManager(config: config, diskStorage: MockLocationDiskStorage(config: config))
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
        MockLocationManager.enableLocationServices = false
        mockManager.delegate = locationManager
        _ = locationManager.isAuthorized
        XCTAssertGreaterThan(MockLocationManager.authorizationStatusCount, 0)
    }

    func testIsFullAccuracyCallsAccuracyAuthorization() {
        if #available(iOS 14, *) {
            mockManager.delegate = locationManager
            _ = locationManager.isFullAccuracy
            XCTAssertEqual(1, mockManager.accuracyAuthorizationCallCount)
        }
    }

    func testRequestAuthorizationCallsRequestWhenInUseAuthByDefault() {
        mockManager.delegate = locationManager
        locationManager.requestAuthorization()
        XCTAssertEqual(1, mockManager.requestWhenInUseAuthorizationCount)
    }

    func testRequestTemporaryFullAccuracyCallsLocationManager() {
        if #available(iOS 14, *) {
            mockManager.delegate = locationManager
            locationManager.requestTemporaryFullAccuracyAuthorization(purposeKey: "because")
            XCTAssertEqual(1, mockManager.requestTemporaryFullAccuracyAuthorizationCount)
        }
    }

    func testRequestTemporaryFullAccuracyDoesNotRunIfLocationNotEnabled() {
        if #available(iOS 14, *) {
            MockLocationManager.enableLocationServices = false
            mockManager.delegate = locationManager
            locationManager.requestTemporaryFullAccuracyAuthorization(purposeKey: "because")
            XCTAssertEqual(0, mockManager.requestTemporaryFullAccuracyAuthorizationCount)
        }
    }

    func testStartUpdatingLocationChangesWhenDefault() {
        mockManager.delegate = locationManager
        onLocationReady(location: locationManager) {
            self.locationManager.startLocationUpdates()
            XCTAssertEqual(1, self.mockManager.startUpdatingLocationCount)
        }
    }

    func testStartUpdatingLocationDoesntRunWhenLocationNotAuthorized() {
        MockLocationManager.enableLocationServices = true
        mockManager.delegate = locationManager
        locationManager.startLocationUpdates()
        XCTAssertEqual(0, mockManager.startUpdatingLocationCount)
    }

    func testLastLocationNilUponInit() throws {
        mockManager.delegate = locationManager
        XCTAssertNil(locationManager.lastLocation)
    }

    func testLastLocationReturnsNilWhenLocationNotEnabled() {
        MockLocationManager.enableLocationServices = false
        mockManager.delegate = locationManager
        XCTAssertNil(locationManager.lastLocation)
    }

    func testMonitoredGeofencesReturnsNilWhenLocationServicesNotAuthorized() {
        MockLocationManager.enableLocationServices = false
        mockManager.delegate = locationManager
        XCTAssertNil(locationManager.monitoredGeofences)
    }

    func testCreatedGeofencesReturnsNilWhenLocationServicesNotAuthorized() {
        MockLocationManager.enableLocationServices = false
        mockManager.delegate = locationManager

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        locationManager.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")

        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")

        locationManager.startMonitoring([region1, region2])

        XCTAssertNil(locationManager.createdGeofences)
    }

    func testStopMonitoringDoesntRunWhenGeofencesEmpty() {
        let emptyGeofences = [CLCircularRegion]()
        mockManager.delegate = locationManager
        locationManager.stopMonitoring(emptyGeofences)
        XCTAssertEqual(0, mockManager.stopMonitoringCount)
    }

    func testValidUrl() {
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        mockManager.delegate = locationManager
        onLocationReady(location: locationManager) {
            XCTAssertEqual(self.locationManager.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
        }
    }

    func testInvalidUrl() {
        config.geofenceUrl = "thisIsNotAValidURL"
        mockManager.delegate = locationManager

        XCTAssertEqual(locationManager.createdGeofences!.count, 0)
    }

    func testValidAsset() {
        config.geofenceFileName = "validGeofences"
        mockManager.delegate = locationManager
        onLocationReady(location: locationManager) {
            let expected = self.locationManager.createdGeofences
            XCTAssertEqual(expected, ["Tealium_Reading", "Tealium_San_Diego"])
        }
    }

    func testInvalidAsset() {
        config.geofenceFileName = "invalidGeofences"
        mockManager.delegate = locationManager
        XCTAssertEqual(locationManager.createdGeofences!.count, 0)
    }

    func testValidAndInvalidAsset() {
        config.geofenceFileName = "validAndInvalidGeofences"
        mockManager.delegate = locationManager

        onLocationReady(location: locationManager) {
            XCTAssertEqual(self.locationManager.createdGeofences!.count, 1)
            XCTAssertEqual(self.locationManager.createdGeofences, ["Tealium_Reading"])
        }
    }

    func testNonExistentAsset() {
        config.geofenceFileName = "SomeJsonFileThatDoesntExist"
        mockManager.delegate = locationManager
        XCTAssertEqual(locationManager.createdGeofences!.count, 0)
    }

    func testValidConfig() {
        mockManager.delegate = locationManager

        onLocationReady(location: locationManager) {
            XCTAssertEqual(self.locationManager.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
        }
    }

    func testInvalidConfig() {
        config = TealiumConfig(account: "IDontExist", profile: "IDontExist", environment: "IDontExist")
        mockManager.delegate = locationManager

        XCTAssertEqual(locationManager.geofences.count, 0)
        XCTAssert(locationManager.createdGeofences!.isEmpty)
    }

    func testInitializeLocationManagerValidDistance() {
        config.updateDistance = 100.0
        mockManager.delegate = locationManager
        XCTAssertEqual(locationManager.locationManager.distanceFilter, 100.0)
    }

    func testStartMonitoringGeofencesGoodArray() {
        config.geofenceFileName = "validGeofences.json"
        mockManager.delegate = locationManager

        onLocationReady(location: locationManager) {
            let regions = self.locationManager.geofences.regions
            self.locationManager.startMonitoring(regions)

            XCTAssertEqual(self.locationManager.locationManager.monitoredRegions.contains(regions[0]), true)
            XCTAssertEqual(self.locationManager.locationManager.monitoredRegions.contains(regions[1]), true)
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
        mockManager.delegate = locationManager

        locationManager.startMonitoring([CLCircularRegion]())

        XCTAssertEqual(locationManager.locationManager.monitoredRegions.count, 0)
    }

    func testStartMonitoringGeofencesGoodRegion() {
        mockManager.delegate = locationManager

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        onLocationReady(location: locationManager) {
            self.locationManager.startMonitoring([region])
            XCTAssertEqual(self.locationManager.locationManager.monitoredRegions.contains(region), true)
        }
    }

    func testStopLocationUpdates() {
        mockManager.delegate = locationManager
        locationManager.stopLocationUpdates()
        XCTAssertGreaterThan(MockLocationManager.authorizationStatusCount, 0)
        XCTAssertEqual(1, mockManager.stopUpdatingLocationCount)
    }

    func testSendGeofenceTrackingEventEntered() {
        let expect = expectation(description: "testSendGeofenceTrackingEventEntered")
        NSTimeZone.default = TimeZone(abbreviation: "PST")!
        let mockLocationDelegate = MockLocationDelegate(didEnter:  { _ in
            expect.fulfill()
        })
        locationManager.locationDelegate = mockLocationDelegate
        mockManager.delegate = locationManager
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
        locationManager.geofences = [geofence]

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        locationManager.lastLocation = location

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        locationManager.sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.entered)

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
            XCTAssertEqual(NSDictionary(dictionary: result), NSDictionary(dictionary: expected))
        }
    }

    func testSendGeofenceTrackingEventExited() {
        let expect = expectation(description: "testSendGeofenceTrackingEventExited")

        let mockLocationDelegate = MockLocationDelegate(didExit: { _ in
            expect.fulfill()
        })

        locationManager.locationDelegate = mockLocationDelegate
        mockManager.delegate = locationManager
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
        locationManager.geofences = [geofence]

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        locationManager.sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.exited)

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
            XCTAssertEqual(NSDictionary(dictionary: result), NSDictionary(dictionary: expected))
        }
    }

    func testDidEnterGeofence() {
        let expect = expectation(description: "testDidEnterGeofence")

        let mockModuleDelegate = MockLocationModuleDelegate { _ in
            expect.fulfill()
        }
        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        let locationModule = createModule(with: config,
                                            delegate: mockModuleDelegate)


        let data: [String: Any] = [TealiumDataKey.geofenceName: "Tealium_San_Diego",
                                   TealiumDataKey.geofenceTransition: LocationKey.entered,
                                   TealiumDataKey.event: LocationKey.entered]

        locationManager.locationDelegate = locationModule
        mockManager.delegate = locationManager

        locationManager.locationDelegate?.didEnterGeofence(data)

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

        let mockModuleDelegate = MockLocationModuleDelegate { _ in
            expect.fulfill()
        }

        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        let locationModule = createModule(with: config,
                                            delegate: mockModuleDelegate)

        locationManager.locationDelegate = locationModule
        mockManager.delegate = locationManager

        let region = CLCircularRegion(center: CLLocationCoordinate2DMake(51.4610304, -0.9707625), radius: CLLocationDistance(100), identifier: "test_region")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.sendGeofenceTrackingEvent(region: region, triggeredTransition: "geofence_entered")

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

        let mockModuleDelegate = MockLocationModuleDelegate { _ in
            expect.fulfill()
        }

        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        let locationModule = createModule(with: config,
                                          delegate: mockModuleDelegate)


        let data: [String: Any] = [TealiumDataKey.geofenceName: "Tealium_San_Diego",
                                   TealiumDataKey.geofenceTransition: LocationKey.exited,
                                   TealiumDataKey.event: LocationKey.exited]
        locationManager.locationDelegate = locationModule
        mockManager.delegate = locationManager

        locationManager.locationDelegate?.didExitGeofence(data)

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
        let locationDelegate = MockLocationDelegate()
        locationManager.locationDelegate = locationDelegate
        mockManager.delegate = locationManager

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        locationManager.lastLocation = location
        XCTAssertEqual(locationManager.lastLocation, location)
    }

    func testStartMonitoring() {
        let mockLocationDelegate = MockLocationDelegate()
        locationManager.locationDelegate = mockLocationDelegate
        mockManager.delegate = locationManager

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        locationManager.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")

        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")

        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        onLocationReady(location: locationManager) {
            self.locationManager.startMonitoring([region1, region2])
            XCTAssertEqual(2, self.mockManager.startMonitoringCount)

            self.locationManager.startMonitoring(geofence: region3)
            XCTAssertEqual(3, self.mockManager.startMonitoringCount)
        }
    }

    func testStopMonitoring() {
        let mockLocationDelegate = MockLocationDelegate()
        locationManager.locationDelegate = mockLocationDelegate
        mockManager.delegate = locationManager

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.032_508_6)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)
        
        onLocationReady(location: locationManager) {
            self.locationManager.lastLocation = location

            let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")
            
            let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")
            
            let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion3")
            
            self.locationManager.startMonitoring([region1, region2, region3])

            self.locationManager.stopMonitoring([region1, region2])
            XCTAssertEqual(2, self.mockManager.stopMonitoringCount)

            self.locationManager.stopMonitoring(geofence: region3)
            XCTAssertEqual(3, self.mockManager.stopMonitoringCount)
        }
    }

    func testMonitoredGeofences() {
        mockManager.delegate = locationManager

        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        onLocationReady(location: locationManager) {
            self.locationManager.startMonitoring([region])

            XCTAssertEqual(["Good_Geofence"], self.locationManager.monitoredGeofences!)
        }
    }

    func testClearMonitoredGeofences() {
        mockManager.delegate = locationManager

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
        locationManager.geofences.append(geofence)

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
        locationManager.geofences.append(geofence2)

        let region1 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance(100.0), identifier: "Good_Geofence")

        let region2 = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0), radius: CLLocationDistance(200.0), identifier: "Another_Good_Geofence")

        locationManager.startMonitoring([region1, region2])
        locationManager.clearMonitoredGeofences()

        XCTAssertEqual(2, mockManager.stopMonitoringCount)
        XCTAssertEqual(0, locationManager.monitoredGeofences!.count)
    }
    
    func testClearMonitoredGeofencesOnlyClearsOwnGeofences() {
        mockManager.delegate = locationManager

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
        locationManager.geofences = [geofence]

        locationManager.startMonitoring([region1, region2])
        locationManager.clearMonitoredGeofences()

        XCTAssertEqual(1, mockManager.stopMonitoringCount)
        XCTAssertEqual(1, locationManager.monitoredGeofences!.count)
        XCTAssertEqual(locationManager.monitoredGeofences!.first!, "Another_Good_Geofence")
    }

    func testDisableLocationManager() {
        config.geofenceFileName = "validGeofences.json"
        mockManager.delegate = locationManager

        locationManager.disable()

        XCTAssertEqual(1, mockManager.stopUpdatingLocationCount)
        XCTAssertEqual(0, locationManager.monitoredGeofences!.count)
        XCTAssertEqual(0, locationManager.geofences.count)
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
