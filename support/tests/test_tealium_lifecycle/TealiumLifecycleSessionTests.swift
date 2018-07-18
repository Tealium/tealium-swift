//
//  TealiumLifecycleSessionTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/15/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumLifecycleSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSessionAutoElapsedFromSleepDateInsertion() {
        let start = Date(timeIntervalSince1970: 1480554000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1480557600)       // 2016 DEC 2 - 02:00 UTC

        let session = TealiumLifecycleSession(withWakeDate: start)
        session.sleepDate = end

        XCTAssertTrue(session.secondsElapsed == 3600, "Unexpected seconds elapsed returned: \(session.secondsElapsed))")
    }

    func testSessionLaunchAutoElapsedFromSleepDateInsertion() {
        let start = Date(timeIntervalSince1970: 1480554000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1480557600)       // 2016 DEC 2 - 02:00 UTC

        let session = TealiumLifecycleSession(withLaunchDate: start)
        session.sleepDate = end

        XCTAssertTrue(session.secondsElapsed == 3600, "Unexpected seconds elapsed returned: \(session.secondsElapsed))")
        XCTAssertTrue(session.wasLaunch == true, "wasLaunch flag was not flipped by init(withLaunchDate:) command")
    }

    func testSessionArhiveUnarchive() {
        let start = Date(timeIntervalSince1970: 1480554000)     // 2016 DEC 1 - 01:00 UTC
        let end = Date(timeIntervalSince1970: 1480557600)       // 2016 DEC 2 - 02:00 UTC

        let session = TealiumLifecycleSession(withWakeDate: start)
        session.sleepDate = end

        let sessionId = "testSession"

        let data = NSKeyedArchiver.archivedData(withRootObject: session)

        UserDefaults.standard.set(data, forKey: sessionId)

        guard let defaultsCheckData = UserDefaults.standard.object(forKey: sessionId) as? Data else {
            XCTFail("Could not unarchive data.")
            return
        }

        guard let defaultsCheck = NSKeyedUnarchiver.unarchiveObject(with: defaultsCheckData) as? TealiumLifecycleSession else {
            XCTFail("Could not unarchive saved data as LifecycleSession")
            return
        }

        XCTAssertTrue(defaultsCheck == session, "Unarchived session: \(defaultsCheck) was different from the original: \(session)")
    }

}
