//
//  SessionManagerTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class SessionManagerTests: XCTestCase {

    var config: TealiumConfig!
    var eventDataManager: DataLayer!
    var mockSessionStarter = MockTealiumSessionStarter()
    var mockURLSession = MockURLSessionSessionStarter()
    var mockDiskStorage = MockDataLayerDiskStorage()
    var timeTraveler = TimeTraveler()
    var lastTrackDate: Date!
    var numberOfTracks: Int!

    override func setUpWithError() throws {
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        eventDataManager = DataLayer(config: config, diskStorage: mockDiskStorage, sessionStarter: mockSessionStarter)
    }

    override func tearDownWithError() throws {
        eventDataManager.numberOfTrackRequests = 0
    }

    func testLastTrackDateNilIncrementsNumberOfTracksBackingAndSetsLastTrackDate() {
        eventDataManager.lastTrackDate = nil
        eventDataManager.numberOfTracks = 0
        XCTAssertEqual(eventDataManager.numberOfTrackRequests, 2)
        XCTAssertNotNil(eventDataManager.lastTrackDate)
    }

    func testTwoTracksInSecondsBetweenTracksStartsNewSession() {
        eventDataManager.isTagManagementEnabled = true
        eventDataManager.shouldTriggerSessionRequest = true
        eventDataManager.lastTrackDate = timeTraveler.travel(by: 20)
        eventDataManager.numberOfTracks = 0
        XCTAssertEqual(mockSessionStarter.sessionRequestCount, 1)
        XCTAssertFalse(eventDataManager.shouldTriggerSessionRequest)
    }

    func testSessionIdReturnsFromPersistentStorage() {
        let sessionId = eventDataManager.sessionId
        XCTAssertNotNil(sessionId)
    }

    func testSessionIdSavesToPersistentStorage() {
        eventDataManager.sessionId = "test123abc"
        let eventDataItem = DataLayerItem(key: "tealium_session_id", value: "test123abc", expires: .distantFuture)
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }

    func testRefreshSessionData() {
        eventDataManager.refreshSessionData()
        XCTAssertNotNil(eventDataManager.sessionId)
        XCTAssertTrue(eventDataManager.shouldTriggerSessionRequest)
    }

    func testSessionRefreshWhenSessionIdNil() {
        eventDataManager.sessionId = nil
        eventDataManager.lastTrackDate = nil
        XCTAssertEqual(eventDataManager.numberOfTrackRequests, 1)
        XCTAssertTrue(eventDataManager.shouldTriggerSessionRequest)
    }

    func testSessionRefreshWhenSessionIdNotNil() {
        eventDataManager.refreshSession()
        XCTAssertNotNil(eventDataManager.all["tealium_session_id"] as! String)
    }

    func testStartNewSessionWhenTagManageMentEnabledTriggerNewSessionFalse() {
        eventDataManager.isTagManagementEnabled = true
        eventDataManager.shouldTriggerSessionRequest = false
        eventDataManager.startNewSession(with: mockSessionStarter)
        XCTAssertEqual(mockSessionStarter.sessionRequestCount, 0)
    }

    func testStartNewSessionWhenTagManageMentNotEnabledTriggerNewSessionTrue() {
        eventDataManager.isTagManagementEnabled = false
        eventDataManager.shouldTriggerSessionRequest = true
        eventDataManager.startNewSession(with: mockSessionStarter)
        XCTAssertEqual(mockSessionStarter.sessionRequestCount, 0)
    }

    func testStartNewSessionWhenTagManageMentEnabledTriggerNewSessionTrue() {
        eventDataManager.isTagManagementEnabled = true
        eventDataManager.shouldTriggerSessionRequest = true
        eventDataManager.startNewSession(with: mockSessionStarter)
        XCTAssertEqual(mockSessionStarter.sessionRequestCount, 1)
    }

}
