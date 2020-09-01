//
//  TealiumLifecycleUnitTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 1/12/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class TealiumLifecycleTests: XCTestCase {

    var lifecycle: Lifecycle!

    override func setUp() {
        super.setUp()

        lifecycle = Lifecycle()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        lifecycle = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // TODO: Optional Keys?
    func testAllExpectedRegularKeys() {
        _ = lifecycle!.newLaunch(at: Date(),
                                 overrideSession: nil)
        let data = lifecycle.asDictionary(type: "launch",
                                          for: Date())

        let expectedKeys = ["lifecycle_dayofweek_local",
                            "lifecycle_dayssincelaunch",
                            "lifecycle_dayssincelastwake",
                            "lifecycle_firstlaunchdate",
                            "lifecycle_firstlaunchdate_MMDDYYYY",
                            "lifecycle_hourofday_local",
                            "lifecycle_launchcount",
                            "lifecycle_priorsecondsawake",
                            "lifecycle_secondsawake",
                            "lifecycle_sleepcount",
                            "lifecycle_totalcrashcount",
                            "lifecycle_totallaunchcount",
                            "lifecycle_totalsecondsawake",
                            "lifecycle_totalsleepcount",
                            "lifecycle_totalwakecount",
                            "lifecycle_type",
                            "lifecycle_wakecount"
        ]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: data, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")
    }

    func testAllExpectedRegularTrackRequestKeys() {
        _ = lifecycle!.newLaunch(at: Date(),
                                 overrideSession: nil)
        let data = lifecycle.asDictionary(type: "launch", for: Date())

        let expectedKeys = ["lifecycle_dayofweek_local",
                            "lifecycle_dayssincelaunch",
                            "lifecycle_dayssincelastwake",
                            "lifecycle_firstlaunchdate",
                            "lifecycle_firstlaunchdate_MMDDYYYY",
                            "lifecycle_hourofday_local",
                            "lifecycle_launchcount",
                            "lifecycle_priorsecondsawake",
                            "lifecycle_secondsawake",
                            "lifecycle_sleepcount",
                            "lifecycle_totalcrashcount",
                            "lifecycle_totallaunchcount",
                            "lifecycle_totalsecondsawake",
                            "lifecycle_totalsleepcount",
                            "lifecycle_totalwakecount",
                            "lifecycle_type",
                            "lifecycle_wakecount"
        ]

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: data, keys: expectedKeys)

        XCTAssertTrue(missingKeys.isEmpty, "Unexpected keys missing:\(missingKeys)")
    }

    func testDayOfWeekLocal() {
        let tz = TimeZone.current
        var expectedDay = "0"
        if tz.identifier.contains("London") {
            // in 1970, the UK observed Daylight Savings (British Summer Time) for the whole year, hence local time at UTC 00:00:00 was 01:00:00
            expectedDay = "5"
        } else if tz.identifier.contains("Los_Angeles") || tz.identifier.contains("Phoenix") {
            expectedDay = "4"
        } else if tz.identifier.contains("Berlin") {
            expectedDay = "5"
        }

        let date = Date(timeIntervalSince1970: 1)

        let day = lifecycle!.dayOfWeekLocal(for: date)
        // Thursday 1st January 1970, 1-indexed, starting from Sunday as day 1
        XCTAssertTrue(day == expectedDay, "Mismatch in dayOfWeekLocal, returned: \(String(describing: day)), expected: \(expectedDay)")
    }

    // TODO: Refactor take test inputs and provided expected outputs
    func testDaysBetweenDates0() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 86_399)

        let days = lifecycle!.daysFrom(earlierDate: date1, laterDate: date2)
        let expectedDays = "0"

        XCTAssertTrue(days == expectedDays, "Mismatch between returned days:\(String(describing: days)) and expected:\(expectedDays)")
    }

    func testDaysBetweenDates1() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 86_400)

        let days = lifecycle!.daysFrom(earlierDate: date1, laterDate: date2)
        let expectedDays = "1"

        XCTAssertTrue(days == expectedDays, "Mismatch between returned days:\(String(describing: days)) and expected:\(expectedDays)")
    }

    func testDaysBetweenDates2() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 172_800)

        let days = lifecycle!.daysFrom(earlierDate: date1, laterDate: date2)
        let expectedDays = "2"

        XCTAssertTrue(days == expectedDays, "Mismatch between returned days:\(String(describing: days)) and expected:\(expectedDays)")
    }

    func testHourOfDayLocal() {
        let tz = TimeZone.current
        var expectedHour = "0"
        if tz.identifier.contains("London") {
            // in 1970, the UK observed Daylight Savings (British Summer Time) for the whole year, hence local time at UTC 00:00:00 was 01:00:00
            expectedHour = "1"
        } else if tz.identifier.contains("Los_Angeles") {
            expectedHour = "16"
        } else if tz.identifier.contains("Phoenix") {
            expectedHour = "17"
        } else if tz.identifier.contains("Berlin") {
            expectedHour = "1"
        }
        let date = Date(timeIntervalSince1970: 1)
        // get local time from lifecycle module
        let hour = lifecycle.hourOfDayLocal(for: date)

        XCTAssertTrue(hour == expectedHour, "Mismatch in hourOfDayLocal, returned:\(String(describing: hour)), expected:\(expectedHour)")
    }

    func testIsFirstWakeTodayOneWake() {
        let date1 = Date(timeIntervalSince1970: 0)
        _ = lifecycle!.newWake(at: date1, overrideSession: nil)
        let isFirstWake = lifecycle!.firstWakeToday

        XCTAssertTrue(isFirstWake, "FirstWakeToday returned:\(String(describing: isFirstWake))")
    }

    func testIsFirstWakeToday2Wakes() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 10)
        _ = lifecycle!.newWake(at: date1, overrideSession: nil)
        _ = lifecycle!.newWake(at: date2, overrideSession: nil)
        let isFirstWake = lifecycle!.firstWakeToday

        XCTAssertFalse(isFirstWake, "FirstWakeToday returned:\(String(describing: isFirstWake))")
    }

    func testIsFirstWakeToday3Wakes() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 86_400)
        let date3 = Date(timeIntervalSince1970: 172_800)
        _ = lifecycle!.newWake(at: date1, overrideSession: nil)
        _ = lifecycle!.newWake(at: date2, overrideSession: nil)
        _ = lifecycle!.newWake(at: date3, overrideSession: nil)

        let isFirstWake = lifecycle!.firstWakeToday

        XCTAssertTrue(isFirstWake, "FirstWakeToday returned:\(String(describing: isFirstWake)), expected:\"true\"")
    }

    func testIsFirstWakeThisMonthFalse() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 10)
        _ = lifecycle!.newWake(at: date1, overrideSession: nil)
        _ = lifecycle!.newWake(at: date2, overrideSession: nil)

        let isFirstWake = lifecycle!.firstWakeThisMonth

        XCTAssertFalse(isFirstWake, "FirstWakeToday returned:\(String(describing: isFirstWake))")
    }

    func testIsFirstWakeThisMonthTrue() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 2_678_401)
        _ = lifecycle!.newWake(at: date1, overrideSession: nil)
        _ = lifecycle!.newWake(at: date2, overrideSession: nil)

        let isFirstWake = lifecycle!.firstWakeThisMonth

        XCTAssertTrue(isFirstWake, "FirstWakeThisMonth returned:\(String(describing: isFirstWake)), expected:\"true\"")
    }

    // TODO: Replace with test file with input data and expected data
    func testISOStringOne() {
        let date = Date(timeIntervalSince1970: 1)
        let expectedString = "1970-01-01T00:00:01Z"
        let dateAsISO = date.iso8601String

        XCTAssertTrue(dateAsISO == expectedString, "Mismatch between returned date string: \(dateAsISO) and expected date string: \(expectedString)")
    }

    func testISOStringNegative() {
        let date = Date(timeIntervalSince1970: -1000)
        let expectedString = "1969-12-31T23:43:20Z"
        let dateAsISO = date.iso8601String

        XCTAssertTrue(dateAsISO == expectedString, "Mismatch between returned date string: \(dateAsISO) and expected date string: \(expectedString)")
    }

    func testISOStringModern() {
        let date = Date(timeIntervalSince1970: 1_483_228_800)
        let expectedString = "2017-01-01T00:00:00Z"
        let dateAsISO = date.iso8601String

        XCTAssertTrue(dateAsISO == expectedString, "Mismatch between returned date string: \(dateAsISO) and expected date string: \(expectedString)")
    }

    func testMMDDYYYYOne() {
        let date = Date(timeIntervalSince1970: 1)
        let expectedString = "01/01/1970"
        let dateString = date.mmDDYYYYString

        XCTAssertTrue(dateString == expectedString, "Mismatch between returned date string: \(dateString) and expected date string: \(expectedString)")
    }

    func testMMDDYYYYNegative() {
        let date = Date(timeIntervalSince1970: -1000.0)
        let expectedString = "12/31/1969"
        let dateString = date.mmDDYYYYString

        XCTAssertTrue(dateString == expectedString, "Mismatch between returned date string: \(dateString) and expected date string: \(expectedString)")
    }

    func testMMDDYYYYModern() {
        let date = Date(timeIntervalSince1970: 1_483_228_800)
        let expectedString = "01/01/2017"
        let dateString = date.mmDDYYYYString

        XCTAssertTrue(dateString == expectedString, "Mismatch between returned date string: \(dateString) and expected date string: \(expectedString)")
    }

    func testSecondsAwake() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 10)

        let expectedSeconds = "10"

        let secondsBetween = lifecycle!.secondsFrom(date1, laterDate: date2)

        XCTAssertTrue(secondsBetween == expectedSeconds, "Mismatch between returned seconds:\(String(describing: secondsBetween)) and expected seconds:\(expectedSeconds)")
    }

    func testSessionSizeLimiting() {
        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 10)

        let initialSession = LifecycleSession(launchDate: date1)
        let session = LifecycleSession(launchDate: date2)
        let sizeLimit = 50
        let testQueue = sizeLimit * 10

        var lifecycle = Lifecycle()
        lifecycle.sessionsSize = sizeLimit

        lifecycle.sessions.append(initialSession)
        for _ in 1..<testQueue {
            lifecycle.sessions.append(session)
        }

        XCTAssert(lifecycle.sessions.count == sizeLimit)
        XCTAssert(lifecycle.sessions.first == initialSession)   // The first session should never be removed
    }

}
