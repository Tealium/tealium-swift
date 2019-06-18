//
//  DispatchQueueTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 30/04/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import Tealium

// note: this will be a long running test (around 6 mins). Grab a coffee while it's running :)
class TealiumPersistentQueueTests: XCTestCase {

    var persistentQueue: TealiumPersistentDispatchQueue?
    var tealiumHelper: TestTealiumHelper?
    let key = "queued_dispatch"

    override func setUp() {
        super.setUp()
        tealiumHelper = TestTealiumHelper()
        persistentQueue = TealiumPersistentDispatchQueue((tealiumHelper?.getConfig())!)
    }

    func testMultiple() {
        for _ in 0...10 {
            tesStorageKey()
            tesSaveDispatchNonEmptyQueue()
            tesSaveDispatchEmptyQueue()
            tesClearQueue()
            tesQueuedDispatches()
        }
    }

    func tesStorageKey() {
        let expectedKey = "testAccount.testProfile.testEnvironment.dispatchqueue"
        if let config = tealiumHelper?.getConfig() {
            assert(expectedKey == MockEmptyDispatchQueue.generateStorageKey(config))
        } else {
            assert(false)
        }
    }

    func tesSaveDispatchNonEmptyQueue() {
        let config = (tealiumHelper?.getConfig())!
        let mockDefaults = MockUserDefaults(suiteName: "xctest")
        if let defaults = mockDefaults {
            let dispatchQueue = MockFullDispatchQueue(config, userDefaultsMock: defaults)
            let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
            dispatchQueue.saveDispatch(track)
            sleep(1)
            let dispatches = defaults.array(forKey: dispatchQueue.storageKey) ?? [[String: Any]]()
            assert(dispatches.count == 3, "Should be a total of 3 dispatches in the queue")
            var found = false
            dispatches.forEach { dispatch in
                if let dispatch = dispatch as? [String: Any] {
                    if dispatch[key] as? String == "true" {
                        found = true
                    }
                }
            }
            assert(found == true, "Expected dispatch could not be found")
        } else {
            assert(false)
            return
        }
    }

    func tesSaveDispatchEmptyQueue() {
        let config = (tealiumHelper?.getConfig())!
        let mockDefaults = MockUserDefaults(suiteName: "xctest")
        if let defaults = mockDefaults {
            let dispatchQueue = MockEmptyDispatchQueue(config, userDefaultsMock: defaults)
            let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
            dispatchQueue.saveDispatch(track)
            sleep(1)
            let dispatches = defaults.array(forKey: dispatchQueue.storageKey) ?? [[String: Any]]()
            assert(dispatches.count == 1, "Should be a total of 1 dispatches in the queue")
            var found = false
            dispatches.forEach { dispatch in
                if let dispatch = dispatch as? [String: Any] {
                    if dispatch[key] as? String == "true" {
                        found = true
                    }
                }
            }
            assert(found == true, "Expected dispatch could not be found")
        } else {
            assert(false)
            return
        }
    }

    func tesClearQueue() {
        if let config = tealiumHelper?.getConfig() {
            if let mockDefaults = MockUserDefaults(suiteName: "xctest") {
                let mockQueue = MockFullDispatchQueue(config, userDefaultsMock: mockDefaults)
                let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
                mockQueue.saveDispatch(track)
                sleep(1)
                mockQueue.clearQueue()
                // added sleep to avoid threading issue (assertion happening before queue has finished clearing)
                sleep(1)
                XCTAssertTrue(mockDefaults.array(forKey: mockQueue.storageKey)?.count == 0, "Clear queue failed. Returned a non-empty queue")
            }
        }
    }

    func tesQueuedDispatches() {
        if let config = tealiumHelper?.getConfig(), let mockDefaults = MockUserDefaults(suiteName: "xctest") {
                let mockQueue = MockNormalDispatchQueue(config, userDefaultsMock: mockDefaults)
                let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
                mockQueue.saveDispatch(track)
                sleep(1)
                let queued = mockQueue.dequeueDispatches()
                assert(queued?.count == 1, "Queued dispatches returned 0 values")
                if let firstDispatch = queued?[0], let val = firstDispatch[key] as? String {
                    assert(val == "true", "Queued dispatches contained unexpected values")
                } else {
                    assert(false, "Queued dispatches did not return any values")
                }
        }
    }
}

class MockFullDispatchQueue: TealiumPersistentDispatchQueue {
    override func dequeueDispatches(clear clearQueue: Bool? = true) -> [[String: Any]]? {
        return [["first_dispatch": "true"], ["second_dispatch": "true"]]
    }
}

class MockNormalDispatchQueue: TealiumPersistentDispatchQueue {

}

class MockEmptyDispatchQueue: TealiumPersistentDispatchQueue {
    override func dequeueDispatches(clear clearQueue: Bool? = true) -> [[String: Any]]? {
        return [[String: Any]]()
    }
}

class MockUserDefaults: UserDefaults {
    var object = [String: Any]()

    override func set(_ value: Any?, forKey defaultName: String) {
        object[defaultName] = value
    }

    override func array(forKey defaultName: String) -> [Any]? {
        guard let item = object[defaultName] else {
            return nil
        }
        if let array = item as? [[String: Any]] {
            return array
        }
        return nil
    }

    override func object(forKey defaultName: String) -> Any? {
        guard let item = object[defaultName] else {
            return nil
        }
        return item
    }
}
