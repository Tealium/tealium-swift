//
//  TealiumLocationUnitTests.swift
//  TealiumLocationTests
//
//  Created by Harry Cassell on 06/09/2019.
//  Copyright © 2019 Harry Cassell. All rights reserved.
//

import XCTest
import CoreLocation
@testable import TealiumCore
@testable import TealiumLocation

class TealiumLocationUnitTests: XCTestCase {

    static var expectations = [XCTestExpectation]()
    var locationManager: MockLocationManager!
    var config: TealiumConfig!
    var tealiumLocationModule: TealiumLocationModule?

    override func setUp() {
        guard let locationManager = MockLocationManager.init(distanceFilter: 500.0, locationAccuracy: kCLLocationAccuracyBest, delegateClass: nil) else {
            XCTFail()
            return
        }

        self.locationManager = locationManager
        TealiumLocationUnitTests.expectations = [XCTestExpectation]()
        config = TealiumConfig(account: "tealiummobile", profile: "location", environment: "dev")
        tealiumLocationModule = TealiumLocationModule(delegate: self)
    }

    override func tearDown() {
        TealiumLocationUnitTests.expectations = [XCTestExpectation]()
    }

    // MARK: Tealium Location Tests

    func testValidUrl() {
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        let tealiumLocation = TealiumLocation(config: config, locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidUrl() {
        config.geofenceUrl = "thisIsNotAValidURL"
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidAsset() {
        config.geofenceFileName = "validGeofences"
        let tealiumLocation = TealiumLocation(config: config,
            bundle: Bundle(for: type(of: self)),
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        let expected = tealiumLocation.createdGeofences
        XCTAssertEqual(expected,  ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidAsset() {
        config.geofenceFileName = "invalidGeofences"
        let tealiumLocation = TealiumLocation(config: config,
            bundle: Bundle(for: type(of: self)),
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidAndInvalidAsset() {
        config.geofenceFileName = "validAndInvalidGeofences"
        let tealiumLocation = TealiumLocation(config: config,
            bundle: Bundle(for: type(of: self)),
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 1)
        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading"])
    }

    func testNonExistentAsset() {
        config.geofenceFileName = "SomeJsonFileThatDoesntExist"
        let tealiumLocation = TealiumLocation(config: config,
            bundle: Bundle(for: type(of: self)),
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences!.count, 0)
    }

    func testValidConfig() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.createdGeofences, ["Tealium_Reading", "Tealium_San_Diego"])
    }

    func testInvalidConfig() {
        config = TealiumConfig(account: "IDontExist", profile: "IDontExist", environment: "IDontExist")
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.geofences.count, 0)
        XCTAssert(tealiumLocation.createdGeofences!.isEmpty)
    }

    func testInitializelocationManagerValidDistance() {
        config.updateDistance = 100.0
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        XCTAssertEqual(tealiumLocation.locationManager.distanceFilter, 100.0)
    }

    func testStartMonitoringGeofencesGoodArray() {
        config.geofenceFileName = "validGeofences.json"

        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let regions = tealiumLocation.geofences.regions
        tealiumLocation.startMonitoring(geofences: regions)

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[0]), true)
        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(regions[1]), true)
    }

    func testStartMonitoringGeofencesBadArray() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.startMonitoring(geofences: [CLCircularRegion]())

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.count, 0)
    }

    func testStartMonitoringGeofencesGoodRegion() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion.init(center: CLLocationCoordinate2D.init(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance.init(100.0), identifier: "Good_Geofence")

        tealiumLocation.startMonitoring(geofences: [region])

        XCTAssertEqual(tealiumLocation.locationManager.monitoredRegions.contains(region), true)
    }

    func testStartLocationUpdatesWithDefaults() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)
        locationManager.delegate = tealiumLocation
        XCTAssert(MockLocationManager.authorizationStatusCount > 0)
        XCTAssertEqual(1, locationManager.startMonitoringSignificantLocationChangesCount)
    }

    func testStartLocationUpdatesWithHighAccuracy() {
        config.useHighAccuracy = true
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)
        locationManager.delegate = tealiumLocation
        XCTAssert(MockLocationManager.authorizationStatusCount > 0)
        XCTAssertEqual(1, locationManager.startUpdatingLocationCount)
    }

    func testStopLocationUpdates() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)
        locationManager.delegate = tealiumLocation
        tealiumLocation.stopLocationUpdates()
        XCTAssert(MockLocationManager.authorizationStatusCount > 0)
        XCTAssertEqual(1, locationManager.stopUpdatingLocationCount)
    }
    
    func testSendGeofenceTrackingEventEntered() {
        let expect = expectation(description: "testSendGeofenceTrackingEventEntered")
        TealiumLocationUnitTests.expectations.append(expect)

        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.entered)

        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testSendGeofenceTrackingEventExited() {
        let expect = expectation(description: "testSendGeofenceTrackingEventExited")
        TealiumLocationUnitTests.expectations.append(expect)

        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086)

        let region = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")

        tealiumLocation.sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.exited)

        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testLatestLocationWhenLastLocationPopulated() {
        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location
        XCTAssertEqual(tealiumLocation.latestLocation, location)
    }
    
    func testLatestLocationWhenLastLocationNotPopulated() {
        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        let latest = tealiumLocation.latestLocation
        XCTAssertEqual(latest.coordinate.latitude, 0.0)
        XCTAssertEqual(latest.coordinate.longitude, 0.0)
        XCTAssertEqual(latest.speed, -1.0)
    }
    
    func testStartMonitoring() {
        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")
        
        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")
        
        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion")
        
        tealiumLocation.startMonitoring(geofences: [region1, region2])
        XCTAssertEqual(2, locationManager.startMonitoringCount)
        
        tealiumLocation.startMonitoring(geofence: region3)
        XCTAssertEqual(3, locationManager.startMonitoringCount)
    }
    
    func testStopMonitoring() {
        let tealiumLocation = TealiumLocation(config: config, locationListener: self,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let coordinate = CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let someDateTime = formatter.date(from: "2020/01/14 22:31")

        let location = CLLocation(coordinate: coordinate, altitude: 10.0, horizontalAccuracy: 10.0, verticalAccuracy: 10.0, course: 10.0, speed: 40.0, timestamp: someDateTime!)

        tealiumLocation.lastLocation = location

        let region1 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion1")
        
        let region2 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion2")
        
        let region3 = CLCircularRegion(center: coordinate, radius: 10.0, identifier: "testRegion3")
        
        tealiumLocation.startMonitoring(geofences: [region1, region2, region3])
        
        tealiumLocation.stopMonitoring(geofences: [region1, region2])
        XCTAssertEqual(2, locationManager.stopMonitoringCount)
        
        tealiumLocation.stopMonitoring(geofence: region3)
        XCTAssertEqual(3, locationManager.stopMonitoringCount)
    }
    
    func testMonitoredGeofences() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region = CLCircularRegion.init(center: CLLocationCoordinate2D.init(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance.init(100.0), identifier: "Good_Geofence")

        tealiumLocation.startMonitoring(geofences: [region])
        
        XCTAssertEqual(["Good_Geofence"], tealiumLocation.monitoredGeofences!)
    }
    
    func testClearMonitoredGeofences() {
        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        let region1 = CLCircularRegion.init(center: CLLocationCoordinate2D.init(latitude: 0.0, longitude: 0.0), radius: CLLocationDistance.init(100.0), identifier: "Good_Geofence")
        
        let region2 = CLCircularRegion.init(center: CLLocationCoordinate2D.init(latitude: 10.0, longitude: 10.0), radius: CLLocationDistance.init(200.0), identifier: "Another_Good_Geofence")

        tealiumLocation.startMonitoring(geofences: [region1, region2])
        tealiumLocation.clearMonitoredGeofences()
        
        XCTAssertEqual(2, locationManager.stopMonitoringCount)
        XCTAssertEqual(0, tealiumLocation.monitoredGeofences!.count)
    }
    
    func testDisableLocationManager() {
        config.geofenceFileName = "validGeofences.json"

        let tealiumLocation = TealiumLocation(config: config,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation
        
        tealiumLocation.disable()
        
        XCTAssertEqual(1, locationManager.stopUpdatingLocationCount)
        XCTAssertEqual(0, tealiumLocation.monitoredGeofences!.count)
        XCTAssertEqual(0, tealiumLocation.geofences.count)
    }

    // MARK: Location Module Tests

    func testEnable() {
        let expect = expectation(description: "testEnable")
        TealiumLocationUnitTests.expectations.append(expect)
        let request = TealiumEnableRequest(config: config, enableCompletion: nil)
        tealiumLocationModule!.enable(request)
        XCTAssertTrue(tealiumLocationModule!.isEnabled)
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testTrackWhenEnabled() {
        let expect = expectation(description: "testTrackWhenEnabled")
        TealiumLocationUnitTests.expectations.append(expect)
        let request = TealiumTrackRequest(data: ["testing": "location"], completion: nil)
        tealiumLocationModule!.track(request)
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testTrackWhenDisabled() {
        let expect = expectation(description: "testTrackWhenDisabled")
        tealiumLocationModule!.isEnabled = false
        TealiumLocationUnitTests.expectations.append(expect)
        let request = TealiumTrackRequest(data: ["testing": "location"], completion: nil)
        tealiumLocationModule!.track(request)
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testDisable() {
        let expect = expectation(description: "testDisable")
        TealiumLocationUnitTests.expectations.append(expect)
        tealiumLocationModule!.disable(TealiumDisableRequest())
        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testDidEnterGeofence() {
        let expect = expectation(description: "testDidEnterGeofence")
        TealiumLocationUnitTests.expectations.append(expect)
        guard let locationManager = MockLocationManager.init(distanceFilter: 500.0, locationAccuracy: kCLLocationAccuracyBest, delegateClass: nil) else {
            XCTFail()
            return
        }
        self.locationManager = locationManager

        let data: [String: Any] = [TealiumLocationKey.geofenceName: "Tealium_San_Diego",
            TealiumLocationKey.geofenceTransition: TealiumLocationKey.entered,
            TealiumKey.event: TealiumLocationKey.entered]


        let tealiumLocation = TealiumLocation(config: config, locationListener: tealiumLocationModule,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.locationListener?.didEnterGeofence(data)

        waitForExpectations(timeout: 3.0, handler: nil)
    }

    func testDidExitGeofence() {
        let expect = expectation(description: "testDidExitGeofence")
        TealiumLocationUnitTests.expectations.append(expect)
        guard let locationManager = MockLocationManager.init(distanceFilter: 500.0, locationAccuracy: kCLLocationAccuracyBest, delegateClass: nil) else {
            XCTFail()
            return
        }
        self.locationManager = locationManager

        let data: [String: Any] = [TealiumLocationKey.geofenceName: "Tealium_San_Diego",
            TealiumLocationKey.geofenceTransition: TealiumLocationKey.exited,
            TealiumKey.event: TealiumLocationKey.exited]


        let tealiumLocation = TealiumLocation(config: config, locationListener: tealiumLocationModule,
            locationManager: locationManager)

        locationManager.delegate = tealiumLocation

        tealiumLocation.locationListener?.didExitGeofence(data)

        waitForExpectations(timeout: 3.0, handler: nil)
    }

}

// XCTAssertTrue(tealiumLocationModule?.tealiumLocationManager.monitoredGeofences?.count == 0)
// XCTAssertTrue((tealiumLocationModule?.tealiumLocationManager.geofences.isEmpty)!)

extension TealiumLocationUnitTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let _ = process as? TealiumTrackRequest {
            TealiumLocationUnitTests.expectations
                .filter {
                    $0.description == "testTrackWhenEnabled" ||
                        $0.description == "testTrackWhenDisabled"
                }
                .forEach { $0.fulfill() }
        } else if let _ = process as? TealiumEnableRequest {
            TealiumLocationUnitTests.expectations
                .filter { $0.description == "testEnable" }
                .forEach { $0.fulfill() }
        } else if let _ = process as? TealiumDisableRequest {
            TealiumLocationUnitTests.expectations
                .filter { $0.description == "testDisable" }
                .forEach { $0.fulfill() }
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let _ = process as? TealiumTrackRequest {
            TealiumLocationUnitTests.expectations
                .filter {
                    $0.description == "testDidEnterGeofence" ||
                        $0.description == "testDidExitGeofence" ||
                        $0.description == "testSendGeofenceTrackingEvent"
                }
                .forEach { $0.fulfill() }
        }
    }
}

extension TealiumLocationUnitTests: LocationListener {

    func didEnterGeofence(_ data: [String: Any]) {
        let expected: [String: Any] = [TealiumKey.event: TealiumLocationKey.entered,
            TealiumLocationKey.geofenceName: "testRegion",
            TealiumLocationKey.geofenceTransition: TealiumLocationKey.entered,
            TealiumLocationKey.latitude: "37.3317",
            TealiumLocationKey.longitude: "-122.0325086",
            TealiumLocationKey.timestamp: "2020-01-15 06:31:00 +0000",
            TealiumLocationKey.speed: "40.0"]
        XCTAssertEqual(expected.keys, data.keys)
        data.forEach {
            guard let value = $0.value as? String,
                let expected = expected[$0.key] as? String else { return }
            XCTAssertEqual(expected, value)
        }
        TealiumLocationUnitTests.expectations
            .filter { $0.description == "testSendGeofenceTrackingEventEntered" }
            .forEach { $0.fulfill() }
    }

    func didExitGeofence(_ data: [String: Any]) {
        let expected: [String: Any] = [TealiumKey.event: TealiumLocationKey.exited,
            TealiumLocationKey.geofenceName: "testRegion",
            TealiumLocationKey.geofenceTransition: TealiumLocationKey.exited]
        XCTAssertEqual(expected.keys, data.keys)
        data.forEach {
            guard let value = $0.value as? String,
                let expected = expected[$0.key] as? String else { return }
            XCTAssertEqual(expected, value)
        }
        TealiumLocationUnitTests.expectations
            .filter { $0.description == "testSendGeofenceTrackingEventExited" }
            .forEach { $0.fulfill() }
    }


}
