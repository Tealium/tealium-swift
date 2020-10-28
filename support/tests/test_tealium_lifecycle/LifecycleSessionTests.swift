//
//  LifecycleSessionTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class LifecycleSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSessionAutoElapsedFromSleepDateInsertion() {
        let start = Date(timeIntervalSince1970: 1_480_554_000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1_480_557_600)       // 2016 DEC 2 - 02:00 UTC

        var session = LifecycleSession(wakeDate: start)
        session.sleepDate = end

        XCTAssertTrue(session.secondsElapsed == 3600, "Unexpected seconds elapsed returned: \(session.secondsElapsed))")
    }

    func testSessionLaunchAutoElapsedFromSleepDateInsertion() {
        let start = Date(timeIntervalSince1970: 1_480_554_000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1_480_557_600)       // 2016 DEC 2 - 02:00 UTC

        var session = LifecycleSession(launchDate: start)
        session.sleepDate = end

        XCTAssertTrue(session.secondsElapsed == 3600, "Unexpected seconds elapsed returned: \(session.secondsElapsed))")
        XCTAssertTrue(session.wasLaunch == true, "wasLaunch flag was not flipped by init(withLaunchDate:) command")
    }

}
