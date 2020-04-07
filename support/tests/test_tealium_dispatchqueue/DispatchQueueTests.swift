//
//  DispatchQueueTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 30/04/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumDispatchQueue
import XCTest

class TealiumPersistentQueueTests: XCTestCase {

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
        let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)

        XCTAssertEqual(persistentQueue?.currentEvents, 3)

        persistentQueue?.saveAndOverwrite([track])
        XCTAssertEqual(persistentQueue?.currentEvents, 1)
    }

    func testPeek() {
        let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
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
        let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
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
        let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
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
        let track = TealiumTrackRequest(data: [key: "true"], completion: nil)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)
        persistentQueue?.appendDispatch(track)

        XCTAssertEqual(persistentQueue?.currentEvents, 3)

        let dispatches = persistentQueue?.dequeueDispatches()
        XCTAssertEqual(dispatches?.count, 3)
    }

    func testRemoveOldDispatches() {
        let date = Date()
        var components = DateComponents()
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "current_date", TealiumKey.timestampUnix: date.unixTimeSeconds], completion: nil))
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "no_timestamp"], completion: nil))
        components.day = -2
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "old_date", TealiumKey.timestampUnix: Calendar.current.date(byAdding: components, to: date)!.unixTimeSeconds], completion: nil))
        components.day = -1
        let newDate = Calendar.current.date(byAdding: components, to: date)
        XCTAssertEqual(persistentQueue?.currentEvents, 3)
        persistentQueue?.removeOldDispatches(5, since: newDate)
        XCTAssertEqual(persistentQueue?.currentEvents, 2)
        persistentQueue?.removeOldDispatches(1)
        XCTAssertEqual(persistentQueue?.currentEvents, 1)
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "current_date", TealiumKey.timestampUnix: date.unixTimeSeconds], completion: nil))
        persistentQueue?.appendDispatch(TealiumTrackRequest(data: ["tealium_event": "no_timestamp"], completion: nil))
        persistentQueue?.removeOldDispatches(2)
        XCTAssertEqual(persistentQueue?.currentEvents, 2)
    }

}
