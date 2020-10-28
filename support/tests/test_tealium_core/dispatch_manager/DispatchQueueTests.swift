//
//  DispatchQueueTests.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class DispatchQueueTests: XCTestCase {

    var persistentQueue: TealiumPersistentDispatchQueue?
    var tealiumHelper: TestTealiumHelper?
    let key = "queued_dispatch"

    static let mockData = [["tealium_event": "hello", "tealium_account": "tealiummobile", "tealium_profile": "demo", "timestamp_unix": Date().unixTimeSeconds], ["tealium_event": "hello2", "tealium_account": "tealiummobile", "tealium_profile": "demo", "timestamp_unix": Date().unixTimeSeconds]]

    override func setUp() {
        super.setUp()
        tealiumHelper = TestTealiumHelper()
        let diskStorage = DispatchQueueMockDiskStorage()
        persistentQueue = TealiumPersistentDispatchQueue(diskStorage: diskStorage)
    }

    func testSaveAndOverwrite() {
        let track = TealiumTrackRequest(data: [key: "true"])
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)

        XCTAssertEqual(persistentQueue?.currentEvents, 3)

        persistentQueue?.saveAndOverwrite([track])
        XCTAssertEqual(persistentQueue?.currentEvents, 1)
    }

    func testPeek() {
        let track = TealiumTrackRequest(data: [key: "true"])
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)

        XCTAssertEqual(persistentQueue?.currentEvents, 3)

        let dispatches = persistentQueue?.peek()
        XCTAssertEqual(dispatches?.count, 3)
        XCTAssertEqual(persistentQueue?.currentEvents, 3)
    }

    func testappendDispatchEmptyQueue() {
        persistentQueue?.diskStorage.delete(completion: nil)
        let track = TealiumTrackRequest(data: [key: "true"])
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        XCTAssertEqual(persistentQueue?.currentEvents, 5)
        let data = persistentQueue?.diskStorage.retrieve(as: [TealiumTrackRequest].self)
        XCTAssertEqual(data!.count, 5)
        guard let savedTrackData = persistentQueue?.peek() else {
            XCTFail()
            return
        }
        savedTrackData.forEach {
            let savedData = $0.trackDictionary
            let testData = track.trackDictionary
            XCTAssertTrue(savedData == testData)
        }
    }

    func testClearQueue() {
        let track = TealiumTrackRequest(data: [key: "true"])
        persistentQueue?.diskStorage.append(track, completion: nil)
        persistentQueue?.diskStorage.append(track, completion: nil)
        var data = persistentQueue?.diskStorage.retrieve(as: [TealiumTrackRequest].self)
        XCTAssertEqual(data!.count, 2)
        persistentQueue?.clearQueue()
        XCTAssertEqual(persistentQueue?.currentEvents, 0)
        data = persistentQueue?.diskStorage.retrieve(as: [TealiumTrackRequest].self)
        XCTAssertEqual(data!.count, 0)
    }

    func testDequeueDispatches() {
        let track = TealiumTrackRequest(data: [key: "true"])
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)

        XCTAssertEqual(persistentQueue?.currentEvents, 3)

        let dispatches = persistentQueue?.dequeueDispatches()
        XCTAssertEqual(dispatches?.count, 3)
    }

    func testRemoveOldDispatches() {
        let date = Date()
        let timeTraveler = TimeTraveler()
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "current_date", TealiumKey.timestampUnix: date.unixTimeSeconds]))
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "no_timestamp"]))
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "old_date", TealiumKey.timestampUnix: timeTraveler.travel(by: daysInFuture(2)).unixTimeSeconds]))
        XCTAssertEqual(persistentQueue?.currentEvents, 3)
        persistentQueue?.removeOldDispatches(5, since: timeTraveler.travel(by: daysInFuture(1)))
        XCTAssertEqual(persistentQueue?.currentEvents, 2)
        persistentQueue?.removeOldDispatches(1)
        XCTAssertEqual(persistentQueue?.currentEvents, 1)
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "current_date", TealiumKey.timestampUnix: date.unixTimeSeconds]))
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "no_timestamp"]))
        persistentQueue?.removeOldDispatches(2)
        XCTAssertEqual(persistentQueue?.currentEvents, 2)
    }

    private func daysInFuture(_ days: Int) -> TimeInterval {
        TimeInterval((days * -86_400))
    }

}
