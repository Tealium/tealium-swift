//
//  TealiumLifecyclePersistentDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 1/11/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class TealiumLifecyclePersistentDataTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLoad() {
        let mockStorage = LifecycleMockDiskStorage()
        let persistentData = TealiumLifecyclePersistentData(diskStorage: mockStorage)
        var lifecycle = TealiumLifecycle()
        lifecycle.countCrashTotal = 5
        let date = Date()
        lifecycle.sessions = [
            TealiumLifecycleSession(withLaunchDate: date)
        ]
        persistentData.save(lifecycle)
        guard let data = persistentData.load() else {
            XCTFail("Persistent data not returned")
            return
        }
        XCTAssertEqual(data.countCrashTotal, 5)
        XCTAssertEqual(data.sessions, lifecycle.sessions)
    }

    func testSave() {
        let mockStorage = LifecycleMockDiskStorage()
        let persistentData = TealiumLifecyclePersistentData(diskStorage: mockStorage)
        var lifecycle = TealiumLifecycle()
        lifecycle.countCrashTotal = 5
        let date = Date()
        lifecycle.sessions = [
        TealiumLifecycleSession(withLaunchDate: date)
        ]
        persistentData.save(lifecycle)
        let data = mockStorage.retrieve(as: TealiumLifecycle.self)
        XCTAssertEqual(data!.countCrashTotal, 5)
        XCTAssertEqual(data!.sessions, lifecycle.sessions)
    }

}
