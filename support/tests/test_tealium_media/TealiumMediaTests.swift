//
//  TealiumMediaTests.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumMedia

class TealiumMediaTests: XCTestCase {
    
    var session: MediaSession!
    var mockMediaService = MockMediaService()

    override func setUpWithError() throws {
        session = SignifigantEventMediaSession(mediaService: mockMediaService)
    }
    
    override func tearDownWithError() throws { }

    // MARK: Init & Setup
    func testMediaSessionInitialized() {
        
    }
    
    func testMediaSessionAddedFromConfig() {
        
    }
    
    func testMediaSessionAdded() {
        
    }
    
    func testMediaSessionRemoved() {
        
    }
    
    func testAllMediaSessionsRemoved() {
        
    }
    
    // MARK: Events
    func testAdBreakStart_Called() {
        session.adBreakStart(AdBreak())
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakStart], 1)
    }
    
    func testAdBreakStart_adBreakAddedToArray() {
        XCTAssertEqual(session.mediaService!.media.adBreaks.count, 0)
        session.adBreakStart(AdBreak())
        XCTAssertEqual(session.mediaService!.media.adBreaks.count, 1)
    }
    
    func testAdBreakStart_TitleSet_WhenDefined() {
        session.adBreakStart(AdBreak(title: "Special Ad Break"))
        XCTAssertEqual(session.mediaService!.media.adBreaks.first!.title, "Special Ad Break")
    }
    
    func testAdBreakStart_TitleDefault_WhenNotDefined() {
        session.adBreakStart(AdBreak())
        XCTAssertEqual(session.mediaService!.media.adBreaks.first!.title, "Ad Break 1")
    }
    
    func testAdBreakComplete_Called() {
        session.mediaService?.media.adBreaks = [AdBreak()]
        session.adBreakComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakComplete], 1)
    }
    
    func testAdStart_Called() {
        session.adStart(Ad())
        XCTAssertEqual(mockMediaService.standardEventCounts[.adStart], 1)
    }
    
    func testAdStart_adAddedToArray() {
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
        session.adStart(Ad())
        XCTAssertEqual(session.mediaService!.media.ads.count, 1)
    }
    
    func testAdStart_AdNameSet_WhenDefined() {
        session.adStart(Ad(name: "Special Ad"))
        XCTAssertEqual(session.mediaService!.media.ads.first!.name, "Special Ad")
    }
    
    func testAdStart_AdNameDefault_WhenNotDefined() {
        session.adStart(Ad())
        XCTAssertEqual(session.mediaService!.media.ads.first!.name, "Ad 1")
    }
    
    func testAdComplete_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.adComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adComplete], 1)
    }
    
    func testAdSkip_Called() {

    }
    
    func testAdSkip_NotCalled_WhenNoAdStart() {
        
    }
    
    func testAdClick_Called() {

    }
    
    func testChapterStart_Called() {

    }
    
    func testChapterComplete_Called() {

    }
    
    func testChapterSkip_Called() {

    }
    
    func testChapterSkip_NotCalled_WhenNoChapterStart() {
        
    }
    
    func testSeekStart_Called() {

    }
    
    func testSeekComplete_Called() {

    }
    
    func testBufferStart_Called() {

    }
    
    func testBufferComplete_Called() {

    }
    
    func testBitrateChange_Called() {

    }
    
    func testSessionStart_Called() {

    }
    
    func testMediaPlay_Called() {

    }
    
    func testMediaPause_Called() {

    }
    
    func testMediaEnd_Called() {

    }
    
    func testSessionComplete_Called() {

    }
    
    func testPlayerStateStart_Called() {

    }
    
    func testPlayerStateEnd_Called() {

    }
    
    func testPing_Called() {
        
    }
    
    // MARK: Variables
    func testMediaSessionVariablesPopulatedWhenSpecified() {
        
    }
    
    func testMediaSessionVariablesNotPopulatedWhenNotSpecified() {
        
    }
    
    func testChapterVariablesPopulatedWhenSpecified() {
        
    }
    
    func testChapterVariablesNotPopulatedWhenNotSpecified() {
        
    }
    
    func testAdVariablesPopulatedWhenSpecified() {
        
    }
    
    func testAdVariablesNotPopulatedWhenNotSpecified() {
        
    }
    
    func testAdBreakVariablesPopulatedWhenSpecified() {
        
    }
    
    func testAdBreakVariablesNotPopulatedWhenNotSpecified() {
        
    }
    
    func testQOEVariablesPopulatedWhenSpecified() {
        
    }
    
    func testQOEVariablesNotPopulatedWhenNotSpecified() {
        
    }
    
    // MARK: Meta Variables
    func testAudioSessionMetaDataPopulated() {
        
    }
    
    func testVideoSessionMetaDataPopulated() {
        
    }
    
    func testAllSessionMetaDataPopulated() {
        
    }
    
    func testOUEMetaDataPopulated() {
        
    }
    
    // MARK: QOE
    func testQOEUpdated() {
        
    }
    
    // MARK: Ads & Ad Break
    func testAdBreakTitleSetWhenSpecified() {
        
    }
    
    func testAdBreakTitleDefaultWhenNotSpecified() {
        
    }
    
    func testAdBreakUUIDGenerated() {
    
    }
    
    func testAdNameSetWhenSpecified() {
        
    }
    
    func testAdNameDefaultWhenNotSpecified() {
        
    }
    
    func testAdUUIDGenerated() {
    
    }
    
    // MARK: Tracking Types
    func testSignifigantEventsTrackingTypeDoesNotSendHeartbeat() {
        
    }
    
    func testSignifigantEventsTrackingTypeDoesNotSendMilestone() {
        
    }
    
    func testSignifigantEventsTrackingTypeDoesNotSendSummary() {
        
    }
    
    func testHeartbeatSentEveryTenSeconds() {
        
    }
    
    func testMilestonesSent() {
        
    }
    
    func testSummarySent() {
        
    }
    
    // MARK: Track

    func testMediaSessionPerformance() throws {
        // performance testing
        self.measure { }
    }

}

