//
//  TealiumLifecycleIntegrationTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 1/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class TealiumLifecycleIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLongRunning() {
        // Load up the input/expected out put JSON file
        guard let allEventsDict = dictionaryFromJSONFile(withName: "lifecycle_events_with_crashes") else {
            XCTFail("Test file missing.")
            return
        }

        let allEvents = allEventsDict["events"] as! NSArray
        var lifecycle = Lifecycle()
        let count = allEvents.count

        for i in 0..<count {
            let event = allEvents[i] as! NSDictionary
            let appVersion = event["app_version"] as! String
            let ts = Double(event["timestamp_unix"] as! String)
            let time = Date(timeIntervalSince1970: ts!)
            let expectedData = event["expected_data"] as! [String: Any]
            let type = expectedData["lifecycle_type"] as! String
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
                XCTFail("Unexpected lifecycyle_type: \(type) for event:\(i)")
            }

            // test for expected keys in payload, excluding keys that may not be present on every event
            for (key, _) in expectedData where key != "lifecycle_diddetectcrash" && key != "lifecycle_isfirstwakemonth" && key != "lifecycle_isfirstwaketoday" {
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

    func dictionaryFromJSONFile(withName: String) -> [String: Any]? {
        let bundle = Bundle(for: type(of: self))

        guard let path = bundle.path(forResource: withName, ofType: "json") else {
            assertionFailure("Target json file with name:\(withName) not found.")
            return nil
        }

        do {
            let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
            do {
                let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                guard let jsonDictionary = jsonResult as? [String: Any] else {
                    assertionFailure("Target json file with name:\(withName) could not be converted to [String:Any].")
                    return nil
                }
                return jsonDictionary
            } catch {
                // Could not convert JSON file to dictionary
                assertionFailure("Target json file with name:\(withName) could not be converted to an NSDictionary.")
                return nil
            }
        } catch {
            // Could not open file at path as NSData
            assertionFailure("Target json file with name:\(withName) could not be opened as NSData.")
            return nil
        }
    }
}
