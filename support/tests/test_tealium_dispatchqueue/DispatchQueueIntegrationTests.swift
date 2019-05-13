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

class TealiumPersistentQueueIntegrationTests: XCTestCase {

    var persistentQueue: TealiumPersistentDispatchQueue?
    var tealiumHelper: TestTealiumHelper?
    let key = "queued_dispatch"

    override func setUp() {
        super.setUp()
        tealiumHelper = TestTealiumHelper()
        persistentQueue = TealiumPersistentDispatchQueue((tealiumHelper?.getConfig())!)
    }

    // clear UserDefaults before each test
    func clearUserDefaults() {
        TealiumPersistentDispatchQueue.queueStorage.set(nil, forKey: (persistentQueue?.storageKey)!)
    }

    func testMultiple() {
        for _ in 0...10 {
            clearUserDefaults()
            tesStorageKey()
            tesSaveDispatchNonEmptyQueue()
            tesSaveDispatchEmptyQueue()
            tesClearQueue()
            tesQueuedDispatches()
            tesPeek()
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
        if let dispatchQueue = persistentQueue {
            dispatchQueue.initializeQueue()
            let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.readWriteQueue.read {
                let dispatches = dispatchQueue.peek()
                assert(dispatches?.count == 5, "Should be a total of 1 dispatches in the queue")
                var found = false
                dispatches?.forEach { dispatch in
                    if dispatch[key] as? String == "true" {
                        found = true
                    }
                }
                assert(found == true, "Expected dispatch could not be found")
            }
        }
    }

    func tesSaveDispatchEmptyQueue() {
        clearUserDefaults()
        if let dispatchQueue = persistentQueue {
            dispatchQueue.initializeQueue()
            let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.readWriteQueue.read {
                let dispatches = dispatchQueue.peek()
                assert(dispatches?.count == 1, "Should be a total of 1 dispatches in the queue")
                var found = false
                dispatches?.forEach { dispatch in
                    if dispatch[key] as? String == "true" {
                        found = true
                    }
                }
                assert(found == true, "Expected dispatch could not be found")
            }
        }
    }

    func tesClearQueue() {
        if let dispatchQueue = persistentQueue {
            dispatchQueue.initializeQueue()
            let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.clearQueue()
            let dispatches = dispatchQueue.dequeueDispatches()
            assert(dispatches?.count == 0, "Clear queue failed. Returned a non-empty queue")
        }
    }

    func tesQueuedDispatches() {
        if let dispatchQueue = persistentQueue {
            dispatchQueue.clearQueue()
            dispatchQueue.initializeQueue()
            let track = TealiumTrackRequest(data: [key: "true", "source": "tesQueuedDispatches"], completion: nil)
            dispatchQueue.saveDispatch(track)
            dispatchQueue.saveDispatch(track)
            assert(dispatchQueue.peek()?.count == 2, "Dispatch queue contained incorrect number of dispatches")
            let allDispatches = dispatchQueue.dequeueDispatches()
            assert(allDispatches?.count == 2, "Dispatch queue contained incorrect number of dispatches")
            let postRemoval = dispatchQueue.dequeueDispatches()
            assert(postRemoval?.count == 0, "Dispatch queue was not cleared correctly")
            if let firstDispatch = allDispatches?[0], let val = firstDispatch[key] as? String {
                assert(val == "true", "Queued dispatches contained unexpected values")
            } else {
                assert(false, "Queued dispatches did not return any values")
            }
        }
    }

    func tesPeek() {
        // make sure items are not removed from the queue after peeking
        if let dispatchQueue = persistentQueue {
            dispatchQueue.clearQueue()
            let track = TealiumTrackRequest(data: [key: "true", "source": "tesQueuedDispatches"], completion: nil)
            dispatchQueue.saveDispatch(track)
            let firstDispatches = dispatchQueue.peek()
            assert(firstDispatches?.count == 1, "Incorrect number of dispatches in the queue")
            let newDispatches = dispatchQueue.peek()
            assert(newDispatches?.count == 1, "Incorrect number of dispatches in the queue")
        }
    }
}
