//
//  TealiumMediaTests.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumMedia

class TealiumMediaTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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
    func testAdBreakStartCalled() {
        
    }
    
    func testAdBreakEndCalled() {
        
    }
    
    func testAdStartCalled() {
        
    }
    
    func testAdCompleteCalled() {
        
    }
    
    func testAdSkipCalled() {

    }
    
    func testAdSkipNotCalledWhenNoAdStart() {
        
    }
    
    func testAdClickCalled() {

    }
    
    func testChapterStartCalled() {

    }
    
    func testChapterCompleteCalled() {

    }
    
    func testChapterSkipCalled() {

    }
    
    func testChapterSkipNotCalledWhenNoChapterStart() {
        
    }
    
    func testSeekStartCalled() {

    }
    
    func testSeekCompleteCalled() {

    }
    
    func testBufferStartCalled() {

    }
    
    func testBufferCompleteCalled() {

    }
    
    func testBitrateChangeCalled() {

    }
    
    func testSessionStartCalled() {

    }
    
    func testMediaPlayCalled() {

    }
    
    func testMediaPauseCalled() {

    }
    
    func testMediaEndCalled() {

    }
    
    func testSessionCompleteCalled() {

    }
    
    func testPlayerStateStartCalled() {

    }
    
    func testPlayerStateEndCalled() {

    }
    
    func testPingCalled() {
        
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

