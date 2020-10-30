//
//  LifecyclePersistentDataTests.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumLifecycle
import XCTest

class LifecyclePersistentDataTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLoad() {
        let mockStorage = LifecycleMockDiskStorage()
        let persistentData = LifecyclePersistentData(diskStorage: mockStorage)
        var lifecycle = Lifecycle()
        lifecycle.countCrashTotal = 5
        let date = Date()
        lifecycle.sessions = [
            LifecycleSession(launchDate: date)
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
        let persistentData = LifecyclePersistentData(diskStorage: mockStorage)
        var lifecycle = Lifecycle()
        lifecycle.countCrashTotal = 5
        let date = Date()
        lifecycle.sessions = [
            LifecycleSession(launchDate: date)
        ]
        persistentData.save(lifecycle)
        let data = mockStorage.retrieve(as: Lifecycle.self)
        XCTAssertEqual(data!.countCrashTotal, 5)
        XCTAssertEqual(data!.sessions, lifecycle.sessions)
    }

}
