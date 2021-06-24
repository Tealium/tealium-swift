//
//  TealiumMediaIntegrationTests.swift
//  TealiumMediaIntegrationTests-iOS
//
//  Created by Christina Schell on 6/16/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumMedia
import XCTest

class TealiumMediaIntegrationTests: XCTestCase {
    
    var mockMediaService = MockMediaService()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSleep_Returns_WhenBackgroundMediaTrackingDisabled() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        let session = IntervalMediaSession(with: mockMediaService)
        session.backgroundStatusResumed = true
        module.activeSessions = [session]
        
        module.sleep()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionEnd], 0)
        XCTAssertTrue(session.backgroundStatusResumed)
    }
    
    func testWake_Returns_WhenBackgroundMediaTrackingDisabled() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        let session = IntervalMediaSession(with: mockMediaService)
        module.activeSessions = [session]
        
        module.wake()
        XCTAssertFalse(session.backgroundStatusResumed)
    }
    
    func testSleep_SetsBackgroundResumedToFalse_WhenBackgroundMediaTrackingEnabled() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.enableBackgroundMediaTracking = true
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        let session = IntervalMediaSession(with: mockMediaService)
        session.backgroundStatusResumed = true
        module.activeSessions = [session]
        
        module.sleep()
        XCTAssertFalse(session.backgroundStatusResumed)
    }
    
    func testSleep_CallsEndSessionAfterConfiguredTime_WhenBackgroundMediaTrackingEnabled() {
        let expect = expectation(description: "CallsEndSessionAfterConfiguredTime")
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.enableBackgroundMediaTracking = true
        config.backgroundMediaAutoEndSessionTime = 3.0
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        let session = IntervalMediaSession(with: mockMediaService)
        session.backgroundStatusResumed = true
        module.activeSessions = [session]
        
        module.sleep()
        TealiumQueues.mainQueue.asyncAfter(deadline:
                                            .now() + 3.5) {
            XCTAssertEqual(self.mockMediaService.standardEventCounts[.sessionEnd], 1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.6)
    }
    
    func testWake_SetsBackgroundResumedToTrue_WhenBackgroundMediaTrackingEnabled() {
        let config = TealiumConfig(account: "account",
                                   profile: "profile",
                                   environment: "env")
        config.enableBackgroundMediaTracking = true
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        let session = IntervalMediaSession(with: mockMediaService)
        session.backgroundStatusResumed = false
        module.activeSessions = [session]
        
        module.wake()
        XCTAssertTrue(session.backgroundStatusResumed)
    }

}
