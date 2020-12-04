//
//  LifecycleModuleTests.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class LifecycleModuleTests: XCTestCase {

    var expectationRequest: XCTestExpectation?
    var sleepExpectation: XCTestExpectation?
    var wakeExpectation: XCTestExpectation?
    var autotrackedRequest: XCTestExpectation?
    var requestProcess: TealiumRequest?
    let helper = TestTealiumHelper()
    var lifecycleModule: LifecycleModule!
    var config: TealiumConfig!
    var returnData: [String: Any]!
    var tealium: Tealium!
    
    func createModule(with config: TealiumConfig? = nil, dataLayer: DataLayerManagerProtocol? = nil) -> LifecycleModule {
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig(), dataLayer: dataLayer ?? DummyDataManager())
        return LifecycleModule(context: context, delegate: self, diskStorage: LifecycleMockDiskStorage(), completion: { _ in })
    }

    override func setUp() {
        super.setUp()
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
        returnData = [String: Any]()
        tealium = Tealium(config: config)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        lifecycleModule = nil
        expectationRequest = nil
        sleepExpectation = nil
        wakeExpectation = nil
        requestProcess = nil
        super.tearDown()
    }

    func testLongRunning() throws {
        // Load up the input/expected out put JSON file
        guard let lifecycleEvents = try? loadLifecycleStubs(from: "lifecycle_events_with_crashes", with: "json") else {
            XCTFail("Test file missing.")
            return
        }

        var lifecycle = Lifecycle()
        guard let events = lifecycleEvents.events else {
            XCTFail("Events empty")
            return
        }
        let count = events.count
        for i in 0..<count {
            let event = events[i]
            let appVersion = event.app_version!
            let ts = Double(event.timestamp_unix!)
            let time = Date(timeIntervalSince1970: ts!)
            let expectedData = event.expected_data.dictionary
            let type = event.expected_data?.lifecycle_type!
            var returnedData = [String: Any]()
            switch type {
            case "launch":
                var overrideSession = LifecycleSession(launchDate: time)
                overrideSession.appVersion = appVersion
                returnedData = lifecycle.newLaunch(at: time, overrideSession: overrideSession)
                if i == 0 {
                    XCTAssertNotNil(returnedData["lifecycle_isfirstlaunch"])
                } else {
                    XCTAssertNil(returnedData["lifecycle_isfirstlaunch"])
                }
            case "sleep":
                returnedData = lifecycle.newSleep(at: time)
                XCTAssertNil(returnedData["lifecycle_isfirstlaunch"])
            case "wake":
                var overrideSession = LifecycleSession(wakeDate: time)
                overrideSession.appVersion = appVersion
                returnedData = lifecycle.newWake(at: time, overrideSession: overrideSession)
                XCTAssertNil(returnedData["lifecycle_isfirstlaunch"])
            default:
                XCTFail("Unexpected lifecycyle_type: \(String(describing: type)) for event:\(i)")
            }

            // test for expected keys in payload, excluding keys that may not be present on every event
            for (key, _) in expectedData! where key != "lifecycle_diddetectcrash" && key != "lifecycle_isfirstwakemonth" && key != "lifecycle_isfirstwaketoday" {
                XCTAssertTrue(returnedData[key] != nil, "Key \(key) was unexpectedly nil")
            }
        }
    }

    func testNewCrashDetected() {
        // Creating test sessions, only interested in secondsElapsed here.
        let start = Date(timeIntervalSince1970: 1_480_554_000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1_480_557_600)       // 2016 DEC 2 - 02:00 UTC
        var sessionSuccess = LifecycleSession(wakeDate: start)
        sessionSuccess.sleepDate = end
        let sessionCrashed = LifecycleSession(wakeDate: start)

        var lifecycle = Lifecycle()
        _ = lifecycle.newLaunch(at: start, overrideSession: nil)

        // Double checking that we aren't returning "true" if we're still in the first launch session.
        let initialDetection = lifecycle.crashDetected
        XCTAssert(initialDetection == nil, "")

        // Check if first launch session resulted in a crash on subsequent launch
        _ = lifecycle.newLaunch(at: Date(), overrideSession: nil)
        XCTAssert(lifecycle.crashDetected == "true", "Should have logged crash as initial launch did not have sleep data. FirstSession: \(String(describing: lifecycle.sessions.first))")

        lifecycle.sessions[0].sleepDate = end
        XCTAssert(lifecycle.crashDetected == nil, "Should not have logged crash as initial launch has sleep data. SessionFirst: \(String(describing: lifecycle.sessions.first)) \nall sessions:\(lifecycle.sessions)")

        lifecycle.sessions.append(sessionCrashed)
        _ = lifecycle.newLaunch(at: Date(), overrideSession: nil)
        XCTAssertTrue(lifecycle.crashDetected == "true", "Crashed prior session not caught. Sessions: \(lifecycle.sessions)")
    }

    func testLifecycleLoadedFromStorage() {
        lifecycleModule = createModule()
        let stored = lifecycleModule.lifecycle
        XCTAssertNotNil(stored)
    }

    func testLifecycleSavedToStorage() {
        lifecycleModule = createModule()
        let lifecycle = Lifecycle()
        lifecycleModule.lifecycle = lifecycle
        let stored = lifecycleModule.lifecycle
        XCTAssertNotNil(stored)
    }

    func testLifecycleAcceptable() {
        let lifecycleModule2 = createModule()
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .launch
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .sleep
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .wake))

        lifecycleModule2.lastLifecycleEvent = .wake
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .launch))
        XCTAssertTrue(lifecycleModule2.lifecycleAcceptable(type: .sleep))
        XCTAssertFalse(lifecycleModule2.lifecycleAcceptable(type: .wake))
    }

    func testAllAdditionalKeysPresent() {
        lifecycleModule = createModule(dataLayer: MockMigratedDataLayerNoData())

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("\n\nFailure: Process not a track request.\n")
            return
        }
        returnData = request.trackDictionary
        let expectedKeys = ["tealium_event"]
        let expectedDictKeys = ["lifecycle_lastwakedate",
                                "lifecycle_firstlaunchdate_MMDDYYYY",
                                "lifecycle_launchcount",
                                "lifecycle_hourofday_local",
                                "autotracked",
                                "lifecycle_secondsawake",
                                "lifecycle_dayofweek_local",
                                "lifecycle_type",
                                "lifecycle_totalcrashcount",
                                "lifecycle_totallaunchcount",
                                "lifecycle_firstlaunchdate",
                                "lifecycle_sleepcount",
                                "lifecycle_totalsecondsawake",
                                "lifecycle_priorsecondsawake",
                                "lifecycle_lastlaunchdate",
                                "lifecycle_dayssincelastwake",
                                "lifecycle_dayssincelaunch",
                                "lifecycle_wakecount",
                                "lifecycle_totalsleepcount",
                                "lifecycle_totalwakecount"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        let missingDictKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedDictKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        XCTAssertTrue(missingDictKeys.isEmpty, "Unexpected keys missing:\(missingDictKeys)")
    }

    func testLifecycleDataMigrated() {
        lifecycleModule = createModule(dataLayer: MockMigratedDataLayer())

        let retrieved = lifecycleModule.lifecycle?.dictionary

        let expected: [String: Any] = [
            "countLaunch": "12",
            "countCrashTotal": "2",
            "countLaunchTotal": "12",
            "countSleep": "5",
            "totalSecondsAwake": "3000",
            "countSleepTotal": "8",
            "countWakeTotal": "7",
        ]

        expected.forEach {
            if let string = retrieved?[$0.key] as? String {
                XCTAssertEqual(string, $0.value as! String)
            }
        }
    }

    func testNormalLifecycleDataWhenNoLegacy() {
        lifecycleModule = createModule(dataLayer: MockMigratedDataLayerNoData())

        guard let request = requestProcess as? TealiumTrackRequest else {
            XCTFail("\n\nFailure: Process not a track request.\n")
            return
        }

        returnData = request.trackDictionary

        let expectedKeys = ["tealium_event"]
        let expectedDictKeys = ["lifecycle_lastwakedate",
                                "lifecycle_firstlaunchdate_MMDDYYYY",
                                "lifecycle_launchcount",
                                "lifecycle_hourofday_local",
                                "autotracked",
                                "lifecycle_secondsawake",
                                "lifecycle_dayofweek_local",
                                "lifecycle_type",
                                "lifecycle_totalcrashcount",
                                "lifecycle_totallaunchcount",
                                "lifecycle_firstlaunchdate",
                                "lifecycle_sleepcount",
                                "lifecycle_totalsecondsawake",
                                "lifecycle_priorsecondsawake",
                                "lifecycle_lastlaunchdate",
                                "lifecycle_dayssincelastwake",
                                "lifecycle_dayssincelaunch",
                                "lifecycle_wakecount",
                                "lifecycle_totalsleepcount",
                                "lifecycle_totalwakecount"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        let missingDictKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedDictKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        XCTAssertTrue(missingDictKeys.isEmpty, "Unexpected keys missing:\(missingDictKeys)")
    }

    func testHasMigratedTrueAfterInit() {
        lifecycleModule = createModule(dataLayer: MockMigratedDataLayerNoData())
        XCTAssertTrue(lifecycleModule.migrated)
    }

    func testMigratedLifecycleKeyDeletedFromDataLayer() {
        let migratedData = MockMigratedDataLayer()
        lifecycleModule = createModule(dataLayer: migratedData)

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedMissingKeys = ["migrated_lifecycle"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedMissingKeys)

        XCTAssertTrue(missingKeys.count == 1, "Unexpected keys missing:\(missingKeys)")
        XCTAssertEqual(migratedData.deleteCount, 1)
    }

    func testManualLifecycleTrackingConfigSetting() {
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayer())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedMissingKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedMissingKeys)

        XCTAssertTrue(missingKeys.count == 2, "Unexpected keys missing:\(missingKeys)")

    }

    func testManualLaunchMethodCall() {
        expectationRequest = expectation(description: "manualLaunchProducesExpectedData")

        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())

        lifecycleModule.launch(at: Date())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_isfirstlaunch"]

        let expectedValues = ["launch", "true"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testManualSleepMethodCall() {
        sleepExpectation = expectation(description: "manualSleepProducesExpectedData")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_sleepcount"]

        let expectedValues = ["sleep", "1"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testManualWakeMethodCall() {
        wakeExpectation = expectation(description: "manualWakeProducesExpectedData")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())

        lifecycleModule.launch(at: Date())
        lifecycleModule.sleep()
        lifecycleModule.wake()

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        let expectedKeys = ["lifecycle_type", "lifecycle_wakecount"]

        let expectedValues = ["wake", "2"]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: returnData, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")

        _ = expectedKeys.enumerated().map {
            if let value = returnData[$1] as? String {
                XCTAssertEqual(value, expectedValues[$0])
            }
        }

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testAutotrackedTrue() {

        autotrackedRequest = expectation(description: "testAutotrackedTrue")
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())

        Tealium.lifecycleListeners.addDelegate(delegate: self)

        lifecycleModule.lifecycleDetected(type: .launch)

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        guard let autotracked = returnData["autotracked"] as? Bool else {
            XCTFail("`autotracked` should not be nil")
            return
        }

        XCTAssertTrue(autotracked)

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }

    func testAutotrackedFalse() {
        autotrackedRequest = expectation(description: "testAutotrackedFalse")
        config.lifecycleAutoTrackingEnabled = false
        lifecycleModule = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())
        lifecycleModule.migrated = true

        self.launch(at: Date())

        if let request = requestProcess as? TealiumTrackRequest {
            returnData = request.trackDictionary
        }

        guard let autotracked = returnData["autotracked"] as? Bool else {
            XCTFail("`autotracked` should not be nil")
            return
        }

        XCTAssertFalse(autotracked)

        self.waitForExpectations(timeout: 8.0, handler: nil)
    }
    
    func testRemovalOfLifecycleListenersOnDeinit() {
        let expect = expectation(description: "testRemovalOfLifecycleListenersOnDeinit")
        config.collectors = [Collectors.Lifecycle]
        var tealium: Tealium? = Tealium(config: config)
        TestTealiumHelper.delay {
            XCTAssertTrue(Tealium.lifecycleListeners.listeningDelegates.count > 0)
            TealiumInstanceManager.shared.removeInstance(config: self.config)
            tealium = nil
            XCTAssertEqual(Tealium.lifecycleListeners.listeningDelegates.count, 0)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
}

extension LifecycleModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {
        expectationRequest?.fulfill()
        if sleepExpectation?.description == "manualSleepProducesExpectedData" &&
            (track.trackDictionary["lifecycle_type"] as! String) == "sleep" {
            sleepExpectation?.fulfill()
        }
        if wakeExpectation?.description == "manualWakeProducesExpectedData" &&
            (track.trackDictionary["lifecycle_type"] as! String) == "wake" {
            wakeExpectation?.fulfill()
        }
        if autotrackedRequest?.description == "testAutotrackedTrue" ||
            autotrackedRequest?.description == "testAutotrackedFalse" {
            autotrackedRequest?.fulfill()
        }
        requestProcess = track
    }

}

extension LifecycleModuleTests: TealiumLifecycleEvents {

    func sleep() {
        // ...
    }

    func wake() {
        // ...
    }

    func launch(at date: Date) {
        lifecycleModule.process(type: .launch, at: Date())
    }

}

fileprivate extension XCTestCase {

    func loadLifecycleStubs(from file: String, with extension: String) throws -> LifecycleStubs {
        let bundle = Bundle(for: classForCoder)
        let url = bundle.url(forResource: file, withExtension: `extension`)
        let data = try Data(contentsOf: url!)
        return try JSONDecoder().decode(LifecycleStubs.self, from: data)
    }

}

fileprivate extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
