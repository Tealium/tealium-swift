//
//  TealiumMediaTests.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumMedia

// TODO: Test correct sequence of events

class TealiumMediaTests: XCTestCase {
    
    var session: MediaSession!
    var mockMediaService = MockMediaService()
    var tealium: Tealium?
    
    override func setUpWithError() throws {
        session = SignificantEventMediaSession(with: mockMediaService)
        MediaContent.numberOfAds = 0
        MediaContent.numberOfAdBreaks = 0
        MediaContent.numberOfChapters = 0
    }
    
    override func tearDownWithError() throws { }

    // MARK: Init & Setup
    func testModule_CreateSession() {
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test")
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config,
                                      dataLayer: DummyDataManager(),
                                      tealium: tealium)
        let module = MediaModule(context: context, delegate: MockModuleDelegate(), diskStorage: nil) { _ in }
        
        let session = module.createSession(from: MediaContent(name: "test", streamType: .aod, mediaType: .video, qoe: QoE(bitrate: 1000)))
        
        guard let _ = session as? SignificantEventMediaSession else {
            XCTFail("createSession failed")
            return
        }
    }
    
    func testMediaSessionFactory_CreatesCorrectTypes() {
        session.mediaService?.media.trackingType = .significant
        let significant = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = significant as? SignificantEventMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
        
        session.mediaService?.media.trackingType = .heartbeat
        let heartbeat = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = heartbeat as? HeartbeatMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
        
        session.mediaService?.media.trackingType = .milestone
        let milestone = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = milestone as? MilestoneMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
        
        session.mediaService?.media.trackingType = .heartbeatMilestone
        let hbMilestone = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = hbMilestone as? HeartbeatMilestoneMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
        
        session.mediaService?.media.trackingType = .summary
        let summary = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = summary as? SummaryMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
    }
    
    // MARK: Events
    func testAdBreakStart_Called() {
        session.startAdBreak(AdBreak())
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakStart], 1)
    }
    
    func testAdBreakStart_adBreakAddedToArray() {
        XCTAssertEqual(session.mediaService!.media.adBreaks.count, 0)
        session.startAdBreak(AdBreak())
        XCTAssertEqual(session.mediaService!.media.adBreaks.count, 1)
    }
    
    func testAdBreakStart_TitleSet_WhenDefined() {
        session.startAdBreak(AdBreak(title: "Special Ad Break"))
        XCTAssertEqual(session.mediaService!.media.adBreaks.first!.title, "Special Ad Break")
    }
    
    func testAdBreakStart_TitleDefault_WhenNotDefined() {
        session.startAdBreak(AdBreak())
        XCTAssertEqual(session.mediaService!.media.adBreaks.first!.title, "Ad Break 1")
    }
    
    func testAdBreakStart_UUIDGenerated() {
        session.startAdBreak(AdBreak())
        XCTAssertNotNil(session.mediaService!.media.adBreaks.first!.uuid)
    }
    
    func testAdBreakComplete_Called() {
        session.mediaService?.media.adBreaks = [AdBreak()]
        session.endAdBreak()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakEnd], 1)
    }
    
    func testAdBreakComplete_NotCalled_WhenNoAdStart() {
        session.endAdBreak()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakEnd], 0)
    }
    
    func testAdBreakComplete_DurationSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(duration: 60)]
        session.endAdBreak()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.duration, 60)
        default:
            break
        }
    }
    
    func testAdBreakComplete_DurationCalculated_WhenNotDefined() {
        session.mediaService?.media.adBreaks = [AdBreak()]
        session.endAdBreak()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertNotNil(adBreak.duration)
        default:
            break
        }
    }
    
    func testAdBreakComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(position: 2)]
        session.endAdBreak()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.position, 2)
        default:
            break
        }
    }
    
    func testAdBreakComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(), AdBreak()]
        session.endAdBreak()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.position, 1)
        default:
            break
        }
    }
    
    func testAdBreakComplete_AdBreakDataIsCorrect() {
        let adBreak = AdBreak(title: "Test Ad Break Complete", id: "abc123", duration: 120, index: 1, position: 2)
        session.mediaService?.media.adBreaks = [adBreak]
        session.endAdBreak()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak):
            XCTAssertEqual(adBreak.title, "Test Ad Break Complete")
            XCTAssertEqual(adBreak.id, "abc123")
            XCTAssertEqual(adBreak.duration, 120)
            XCTAssertEqual(adBreak.index, 1)
            XCTAssertEqual(adBreak.position, 2)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testAdStart_Called() {
        session.startAd(Ad())
        XCTAssertEqual(mockMediaService.standardEventCounts[.adStart], 1)
    }
    
    func testAdStart_adAddedToArray() {
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
        session.startAd(Ad())
        XCTAssertEqual(session.mediaService!.media.ads.count, 1)
    }
    
    func testAdStart_AdNameSet_WhenDefined() {
        session.startAd(Ad(name: "Special Ad"))
        XCTAssertEqual(session.mediaService!.media.ads.first!.name, "Special Ad")
    }
    
    func testAdStart_AdNameDefault_WhenNotDefined() {
        session.startAd(Ad())
        XCTAssertEqual(session.mediaService!.media.ads.first!.name, "Ad 1")
    }
    
    func testAdStart_UUIDGenerated() {
        session.startAd(Ad())
        XCTAssertNotNil(session.mediaService!.media.ads.first!.uuid)
    }
    
    func testAdComplete_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.endAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adEnd], 1)
    }
    
    func testAdComplete_adRemovedFromArray() {
        session.mediaService?.media.ads = [Ad()]
        session.endAd()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testAdComplete_NotCalled_WhenNoAdStart() {
        session.endAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adEnd], 0)
    }
    
    func testAdComplete_DurationSet_WhenDefined() {
        session.mediaService?.media.ads = [Ad(duration: 30)]
        session.endAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.duration, 30)
        default:
            break
        }
    }
    
    func testAdComplete_DurationCalculated_WhenNotDefined() {
        session.mediaService?.media.ads = [Ad()]
        session.endAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertNotNil(ad.duration)
        default:
            break
        }
    }
    
    func testAdComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(position: 3)]
        session.endAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.position, 3)
        default:
            break
        }
    }
    
    func testAdComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.ads = [Ad(), Ad()]
        session.endAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.position, 1)
        default:
            break
        }
    }
    
    func testAdComplete_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Complete", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.skipAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad):
            XCTAssertEqual(ad.name, "Test Ad Complete")
            XCTAssertEqual(ad.id, "Abc123")
            XCTAssertEqual(ad.duration, 30)
            XCTAssertEqual(ad.position, 1)
            XCTAssertEqual(ad.advertiser, "google")
            XCTAssertEqual(ad.creativeId, "test123")
            XCTAssertEqual(ad.campaignId, "camp123")
            XCTAssertEqual(ad.placementId, "place123")
            XCTAssertEqual(ad.siteId, "test site id")
            XCTAssertEqual(ad.creativeUrl, "https://creative.com")
            XCTAssertEqual(ad.numberOfLoads, 1)
            XCTAssertEqual(ad.pod, "ad pod")
            XCTAssertEqual(ad.playerName, "some ad player")
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    
    func testAdSkip_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.skipAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adSkip], 1)
    }
    
    func testAdSkip_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Skip", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.skipAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad):
            XCTAssertEqual(ad.name, "Test Ad Skip")
            XCTAssertEqual(ad.id, "Abc123")
            XCTAssertEqual(ad.duration, 30)
            XCTAssertEqual(ad.position, 1)
            XCTAssertEqual(ad.advertiser, "google")
            XCTAssertEqual(ad.creativeId, "test123")
            XCTAssertEqual(ad.campaignId, "camp123")
            XCTAssertEqual(ad.placementId, "place123")
            XCTAssertEqual(ad.siteId, "test site id")
            XCTAssertEqual(ad.creativeUrl, "https://creative.com")
            XCTAssertEqual(ad.numberOfLoads, 1)
            XCTAssertEqual(ad.pod, "ad pod")
            XCTAssertEqual(ad.playerName, "some ad player")
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testAdSkip_adRemovedFromArray() {
        session.mediaService?.media.ads = [Ad()]
        session.skipAd()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testAdSkip_NotCalled_WhenNoAdStart() {
        session.skipAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adSkip], 0)
    }
    
    func testAdClick_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.clickAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adClick], 1)
    }
    
    func testAdClick_NotCalled_WhenNoAdStart() {
        session.clickAd()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adClick], 0)
    }
    
    func testAdClick_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Click", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.clickAd()
        switch mockMediaService.updatedSegment {
        case .ad(let ad):
            XCTAssertEqual(ad.name, "Test Ad Click")
            XCTAssertEqual(ad.id, "Abc123")
            XCTAssertEqual(ad.duration, 30)
            XCTAssertEqual(ad.position, 1)
            XCTAssertEqual(ad.advertiser, "google")
            XCTAssertEqual(ad.creativeId, "test123")
            XCTAssertEqual(ad.campaignId, "camp123")
            XCTAssertEqual(ad.placementId, "place123")
            XCTAssertEqual(ad.siteId, "test site id")
            XCTAssertEqual(ad.creativeUrl, "https://creative.com")
            XCTAssertEqual(ad.numberOfLoads, 1)
            XCTAssertEqual(ad.pod, "ad pod")
            XCTAssertEqual(ad.playerName, "some ad player")
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testAdClick_adRemovedFromArray() {
        session.mediaService?.media.ads = [Ad()]
        session.clickAd()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testChapterStart_Called() {
        session.startChapter(Chapter(name: "Chapter 1", duration: 900))
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterStart], 1)
    }
    
    func testChapterStart_ChapterAddedToArray() {
        session.startChapter(Chapter(name: "Chapter 1", duration: 900))
        XCTAssertEqual(session.mediaService!.media.chapters.count, 1)
    }
    
    func testChapterComplete_Called() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.endChapter()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterEnd], 1)
    }
    
    func testChapterComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900, position: 3)]
        session.endChapter()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter): XCTAssertEqual(chapter.position, 3)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testChapterComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900), Chapter(name: "Chapter 2", duration: 960)]
        session.endChapter()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter): XCTAssertEqual(chapter.position, 2)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
        
    func testChapterComplete_ChapterDataIsCorrect() {
        let chapter = Chapter(name: "Test Chapter Complete", duration: 960, position: 1, startTime: Date(), metadata: ["chapter_meta_key": "chapter_meta_value"])
        session.mediaService?.media.chapters = [chapter]
        session.endChapter()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter):
            XCTAssertEqual(chapter.name, "Test Chapter Complete")
            XCTAssertEqual(chapter.duration, 960)
            XCTAssertEqual(chapter.position, 1)
            XCTAssertNotNil(chapter.startTime)
            XCTAssertNotNil(chapter.metadata?.value)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }

    func testChapterComplete_NotCalled_WhenNoChapterStart() {
        session.endChapter()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterEnd], 0)
    }
        
    func testChapterComplete_ChapterRemovedFromArray() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.endChapter()
        XCTAssertEqual(session.mediaService!.media.chapters.count, 0)
    }
    
    func testChapterSkip_Called() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.skipChapter()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterSkip], 1)
    }
        
    func testChapterSkip_ChapterDataIsCorrect() {
        let chapter = Chapter(name: "Test Chapter Skip", duration: 960, position: 1, startTime: Date(), metadata: ["chapter_meta_key": "chapter_meta_value"])
        session.mediaService?.media.chapters = [chapter]
        session.skipChapter()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter):
            XCTAssertEqual(chapter.name, "Test Chapter Skip")
            XCTAssertEqual(chapter.duration, 960)
            XCTAssertEqual(chapter.position, 1)
            XCTAssertNotNil(chapter.startTime)
            XCTAssertNotNil(chapter.metadata?.value)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testChapterSkip_ChapterRemovedFromArray() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.skipChapter()
        XCTAssertEqual(session.mediaService!.media.chapters.count, 0)
    }
    
    func testChapterSkip_NotCalled_WhenNoChapterStart() {
        session.skipChapter()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterSkip], 0)
    }
    
    func testSeekStart_Called() {
        session.startSeek()
        XCTAssertEqual(mockMediaService.standardEventCounts[.seekStart], 1)
    }
    
    func testSeekComplete_Called() {
        session.endSeek()
        XCTAssertEqual(mockMediaService.standardEventCounts[.seekEnd], 1)
    }
    
    func testBufferStart_Called() {
        session.startBuffer()
        XCTAssertEqual(mockMediaService.standardEventCounts[.bufferStart], 1)
    }
    
    func testBufferComplete_Called() {
        session.endBuffer()
        XCTAssertEqual(mockMediaService.standardEventCounts[.bufferEnd], 1)
    }
    
    func testBitrateChange_Called() {
        session.bitrate = 1500
        XCTAssertEqual(mockMediaService.standardEventCounts[.bitrateChange], 1)
    }
    
    func testBitrate_ReturnsQOEBitrate() {
        XCTAssertEqual(session.bitrate, 1000)
    }
    
    func testBitrateChange_UpdatesQOE() {
        session.bitrate = 1500
        XCTAssertEqual(mockMediaService.media.qoe.bitrate, 1500)
    }
    
    func testSessionStart_Called() {
        session.startSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionStart], 1)
    }
    
    func testMediaPlay_Called() {
        session.play()
        XCTAssertEqual(mockMediaService.standardEventCounts[.play], 1)
    }
    
    func testMediaPause_Called() {
        session.pause()
        XCTAssertEqual(mockMediaService.standardEventCounts[.pause], 1)
    }
    
    func testMediaStop_Called() {
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.stop], 1)
    }
    
    func testSessionComplete_Called() {
        session.endSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionEnd], 1)
    }
    
    func testPlaybackSpeed_ReturnsQOEPlaybackSpeed() {
        session.mediaService?.media.qoe.playbackSpeed = 0.25
        XCTAssertEqual(session.playbackSpeed, 0.25)
    }
    
    func testPlaybackSpeed_ReturnsDeafult_WhenNotDefined() {
        XCTAssertEqual(session.playbackSpeed, 1.0)
    }
    
    func testPlaybackSpeed_UpdatesQOE() {
        session.playbackSpeed = 1.5
        XCTAssertEqual(mockMediaService.media.qoe.playbackSpeed, 1.5)
    }
    
    func testDroppedFrames_ReturnsQOEDroppedFrames() {
        session.mediaService?.media.qoe.droppedFrames = 5
        XCTAssertEqual(session.droppedFrames, 5)
    }
    
    func testDroppedFrames_ReturnsDeafult_WhenNotDefined() {
        XCTAssertEqual(session.droppedFrames, 0)
    }
    
    func testDroppedFrames_UpdatesQOE() {
        session.droppedFrames = 4
        XCTAssertEqual(mockMediaService.media.qoe.droppedFrames, 4)
    }
    
    func testPlayerStateReturnsExpectedValue() {
        XCTAssertEqual(session.playerState, .fullscreen)
    }
    
    func testPlayerStateStart_Called() {
        session.mediaService?.media.state = nil
        session.playerState = .closedCaption
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStart], 1)
        XCTAssertEqual(session.mediaService?.media.state, .closedCaption)
    }
    
    func testPlayerStateStop_Called() {
        session.mediaService?.media.state = nil
        session.playerState = .closedCaption
        session.playerState = .fullscreen
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStop], 1)
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStart], 2)
        XCTAssertEqual(session.mediaService?.media.state, .fullscreen)
    }
    
    func testCustomEvent_Called() {
        session.custom("My Custom Event")
        XCTAssertEqual(mockMediaService.customEvent.count, 1)
    }
    
    func testCustomEvent_NameSet() {
        session.custom("My Custom Event 2")
        XCTAssertEqual(mockMediaService.customEvent.name, "My Custom Event 2")
    }
    
    func testCalculate_ReturnsExpectedValue_WhenDateProvided() {
        let mockDate = TimeTraveler().travel(by: -60)
        guard let actual = session.calculate(duration: mockDate) else {
            return XCTFail("Calculate should not return nil")
        }
        XCTAssertEqual(actual, 60)
    }
    
    func testCalculate_ReturnsExpectedNil_WhenDateProvided() {
        let actual = session.calculate(duration: nil)
        XCTAssertNil(actual)
    }
    
    // MARK: Tracking Types - Significant
    func testSignificantEvents_TrackingType_DoesNotSendHeartbeat() {
        session.startSession()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 0)
    }
    
    func testSignificantEvents_TrackingType_DoesNotSendMilestone() {
        session.startSession()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], 0)
    }
    
    func testSignificantEvents_TrackingType_DoesNotSendSummary() {
        session.startSession()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.summary], 0)
    }
    
    // MARK: Tracking Types - Heartbeat
    func testHeartbeatManualPing_CallsTrack() {
        session = HeartbeatMediaSession(with: mockMediaService)
        session.startSession()
        session.ping()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 1)
    }
    
    func testHeartbeatStartSession_SetsTimerEventHandler() {
        let timer = MockRepeatingTimer()
        session = HeartbeatMediaSession(with: mockMediaService, timer)
        session.startSession()
        XCTAssertNotNil(timer.eventHandler)
    }
    
    func testHeartbeatStartSession_CallsSuperTrack() {
        session = HeartbeatMediaSession(with: mockMediaService)
        session.startSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionStart], 1)
    }
    
    func testHeartbeatStartSession_CallsTimerResume() {
        let timer = MockRepeatingTimer()
        session = HeartbeatMediaSession(with: mockMediaService, timer)
        session.startSession()
        XCTAssertEqual(timer.resumCount, 1)
    }
    
    func testHeartbeatEndSession_CallsSuperTrack() {
        session = HeartbeatMediaSession(with: mockMediaService)
        session.endSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionEnd], 1)
    }
    
    func testStopPing_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = HeartbeatMediaSession(with: mockMediaService, timer)
        session.stopPing()
        XCTAssertEqual(timer.suspendCount, 1)
    }
    
    func testHeartbeatEndSession_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = HeartbeatMediaSession(with: mockMediaService, timer)
        session.endSession()
        XCTAssertEqual(timer.suspendCount, 1)
    }
        
    func testHeartbeatDeinit_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = HeartbeatMediaSession(with: mockMediaService, timer)
        session.startSession()
        session = nil
        XCTAssertEqual(timer.suspendCount, 1)
    }
    
    // MARK: Tracking Types - Milestone
    func testMilestoneSartSession_SetsEventHandler() {
        let mockTimer = MockRepeatingTimer()
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0, mockTimer)
        session.startSession()
        XCTAssertNotNil(mockTimer.eventHandler)
    }
    
    func testMilestoneSartSession_CallsTimerResume() {
        let timer = MockRepeatingTimer()
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0, timer)
        session.startSession()
        XCTAssertEqual(timer.resumCount, 1)
    }
    
    func testtMilestoneEndSession_CallsSuperTrack() {
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.endSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionEnd], 1)
    }
    
    func testMilestoneStopPing_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0, timer)
        session.stopPing()
        XCTAssertEqual(timer.suspendCount, 1)
    }
    
    func testtMilestoneEndSession_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0, timer)
        session.endSession()
        XCTAssertEqual(timer.suspendCount, 1)
    }
        
    func testtMilestoneDeinit_CallsTimerSuspend() {
        let timer = MockRepeatingTimer()
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0, timer)
        session.startSession()
        session = nil
        XCTAssertEqual(timer.suspendCount, 1)
    }
    
    func testPing_SetsCorrectMilestoneValue() {
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -13)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "10%")
        
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -33)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "25%")
        
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -65)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "50%")
        
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -98)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "75%")
        
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -117)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "90%")
        
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -128)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.media.milestone, "100%")
    }
    
    func testPing_DoesNotCallTrack_WhenRangeIsNotWithinMilestone() {
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -9)
        session = MilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], 0)
    }
    
    func testMilestones_SentInTrack() {
        var count = 0
        session = MilestoneMediaSession(with: mockMediaService, interval: 5.0)
        Milestone.allCases.forEach {
            count += 1
            session?.sendMilestone($0)
            XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], count)
            XCTAssertEqual(mockMediaService.media.milestone, $0.rawValue)
        }
    }
    
    // MARK: Tracking Types - Heartbeat + Milestone
    func testPing_CallsTrackWithHeartbeat_EveryTenthSecond() {
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -20)
        session = HeartbeatMilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 1)
        XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], 0)
    }
    
    func testPing_CallsTrack_WithHeartbeatAndMilestone() {
        mockMediaService.media.duration = 100
        mockMediaService.media.startTime = TimeTraveler().travel(by: -10)
        session = HeartbeatMilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 1)
        XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], 1)
        XCTAssertEqual(mockMediaService.media.milestone, "10%")
    }
    
    func testPing_DoesNotCallTrack_WithHeartbeatAndMilestone() {
        mockMediaService.media.duration = 130
        mockMediaService.media.startTime = TimeTraveler().travel(by: -19.5)
        session = HeartbeatMilestoneMediaSession(with: mockMediaService, interval: 1.0)
        session.ping()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 0)
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 0)
        XCTAssertNil(mockMediaService.media.milestone)
    }
    
    // MARK: Tracking Types - Summary
    func testSummarySartSession_InitializesModel() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        XCTAssertNotNil(session.mediaService?.media.summary)
    }
    
    func testSummaryPlay_IncrementsPlayCounter() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.play()
        XCTAssertEqual(session.mediaService?.media.summary?.plays, 1)
    }
    
    func testSummaryPlay_SetsPlayStartTime() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.play()
        XCTAssertNotNil(session.mediaService?.media.summary?.playStartTime)
    }
    
    func testSummaryStartChapter_IncrementsChapterCounter() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startChapter(Chapter(name: "Chapter 1", duration: 30))
        XCTAssertEqual(session.mediaService?.media.summary?.chapterStarts, 1)
    }
    
    func testSkipChapter_IncrementsChapterSkips() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.skipChapter()
        XCTAssertEqual(session.mediaService?.media.summary?.chapterSkips, 1)
    }
    
    func testEndChapter_IncrementsChapterEnds() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.endChapter()
        XCTAssertEqual(session.mediaService?.media.summary?.chapterEnds, 1)
    }
    
    func testStartBuffer_SetsBufferStartTime() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startBuffer()
        XCTAssertNotNil(session.mediaService?.media.summary?.bufferStartTime)
    }
    
    func testEndBuffer_IncrementsTotalBufferTime_WhenStartBufferHasBeenCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        let mockStartTime = TimeTraveler().travel(by: -60)
        session.mediaService?.media.summary?.sessionStart = mockStartTime
        session.mediaService?.media.summary?.bufferStartTime = mockStartTime + 30
        session.endBuffer()
        XCTAssertEqual(session.mediaService!.media.summary!.totalBufferTime, 30)
    }
    
    func testEndBuffer_DoesNotIncrementTotalBufferTime_WhenStartBufferHasBeenCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.endBuffer()
        XCTAssertEqual(session.mediaService?.media.summary?.totalBufferTime, 0)
    }
    
    func testEndBuffer_DoesNotIncrementTotalBufferTime_WhenStartTimeIsNil() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startBuffer()
        session.mediaService?.media.summary?.bufferStartTime = nil
        session.endBuffer()
        XCTAssertEqual(session.mediaService?.media.summary?.totalBufferTime, 0)
    }
    
    func testStartSeek_SetsSeekStartTime() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startSeek()
        XCTAssertNotNil(session.mediaService?.media.summary?.seekStartTime)
    }
    
    func testEndSeek_IncrementsTotalSeekTime_WhenStartSeekHasBeenCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        let mockStartSeekTime = TimeTraveler().travel(by: -30)
        session.startSession()
        session.mediaService?.media.summary?.seekStartTime = mockStartSeekTime
        session.endSeek()
        XCTAssertEqual(session.mediaService!.media.summary!.totalSeekTime, 30)
    }
    
    func testEndSeek_DoesNotIncrementTotalSeekTime_WhenStartSeekHasBeenCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.endSeek()
        XCTAssertEqual(session.mediaService?.media.summary?.totalSeekTime, 0)
    }
    
    func testEndSeek_DoesNotIncrementTotalSeekTime_WhenStartTimeIsNil() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.mediaService?.media.summary?.sessionStartTime = nil
        session.startSeek()
        session.endSeek()
        XCTAssertEqual(session.mediaService?.media.summary?.totalSeekTime, 0)
    }
    
    func testSummaryStartAd_IncrementsAdCounter() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startAd(Ad())
        XCTAssertEqual(session.mediaService?.media.summary?.ads, 1)
    }
    
    func testSummaryStartAd_PopulatesUUIDArray() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startAd(Ad())
        XCTAssertEqual(session.mediaService?.media.summary?.adUUIDs.count, 1)
    }
    
    func testSummaryStartAd_SetsAdStartTime() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startAd(Ad())
        XCTAssertNotNil(session.mediaService!.media.summary!.adStartTime)
    }
    
    func testSummarySkipAd_IncrementsAdCounters_WhenAdStartIsCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        let mockAdStartTime = TimeTraveler().travel(by: -30)
        session.mediaService!.media.summary!.adStartTime = mockAdStartTime
        session.skipAd()
        XCTAssertEqual(session.mediaService?.media.summary?.adSkips, 1)
        XCTAssertEqual(session.mediaService!.media.summary!.totalAdTime, 30)
    }
    
    func testSummarySkipAd_DoesNotIncrementAdCounters_WhenAdStartIsNotCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.skipAd()
        XCTAssertEqual(session.mediaService?.media.summary?.adSkips, 0)
        XCTAssertEqual(session.mediaService?.media.summary?.adEnds, 0)
        XCTAssertEqual(session.mediaService?.media.summary?.totalAdTime, 0)
    }

    func testSummaryEndAd_IncrementsAdCounters_WhenAdStartIsCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startAd(Ad())
        session.endAd()
        XCTAssertEqual(session.mediaService?.media.summary?.adEnds, 1)
        XCTAssertEqual(session.mediaService?.media.summary?.ads, 1)
    }
    
    func testSummaryEndAd_DoesNotIncrementAdCounters_WhenAdStartIsNotCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.endAd()
        XCTAssertEqual(session.mediaService?.media.summary?.adEnds, 0)
        XCTAssertEqual(session.mediaService?.media.summary?.totalAdTime, 0)
    }
    
    func testSummaryPause_IncrementsPlayCounters_WhenPlayIsCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.play()
        session.pause()
        XCTAssertEqual(session.mediaService?.media.summary?.pauses, 1)
    }
    
    func testSummaryPause_DoesNotIncrementPlayCounters_WhenAdPlayIsNotCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.pause()
        XCTAssertEqual(session.mediaService?.media.summary?.pauses, 0)
        XCTAssertEqual(session.mediaService?.media.summary?.totalPlayTime, 0)
    }
    
    func testSummaryStop_IncrementsPlayCounters_WhenPlayIsCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.play()
        session.stop()
        XCTAssertEqual(session.mediaService?.media.summary?.stops, 1)
        XCTAssertNotNil(session.mediaService?.media.summary?.totalPlayTime)
    }
    
    func testSummaryStop_DoesNotIncrementPlayCounters_WhenAdPlayIsNotCalled() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.stop()
        XCTAssertEqual(session.mediaService?.media.summary?.stops, 0)
        XCTAssertEqual(session.mediaService?.media.summary?.totalPlayTime, 0)
    }
    
    func testSummaryEndSession_SetsSessionEnd() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startSession()
        session.endSession()
        XCTAssertNotNil(session.mediaService?.media.summary?.sessionEnd)
        XCTAssertTrue(session.mediaService!.media.summary!.playToEnd)
    }
    
    func testSummaryEndSession_CallsSummary() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.startSession()
        session.endSession()
        XCTAssertNotNil(session.mediaService?.media.summary?.duration)
    }
    
    func testSummary_CalculatesAndSetsValues_WhenMediaSummaryNotNil() {
        let mockSummary = Summary()
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.mediaService?.media.summary = mockSummary
        session.play()
        session.startChapter(Chapter(name: "Chapter 1", duration: 30))
        session.startAdBreak(AdBreak())
        session.startAd(Ad())
        session.skipAd()
        session.startAd(Ad())
        session.endAd()
        session.endAdBreak()
        session.skipChapter()
        session.startChapter(Chapter(name: "Chapter 2", duration: 30))
        session.pause()
        session.play()
        session.stop()
        session.endChapter()
        session.endSession()
        let actual = session.mediaService?.media.summary
        XCTAssertNotNil(actual?.sessionStartTime)
        XCTAssertNotNil(actual?.duration)
        XCTAssertNotNil(actual?.sessionEndTime)
        XCTAssertEqual(actual?.percentageChapterComplete, 50.0)
        XCTAssertEqual(actual?.percentageAdComplete, 50.0)
    }
    
    func testSummary_CalculatesPercentageAdTime_WhenMediaSummaryNotNil() {
        let mockSummary = Summary()
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.mediaService?.media.summary = mockSummary
        session.mediaService?.media.summary?.totalPlayTime = 30
        session.mediaService?.media.summary?.totalAdTime = 15
        session.endSession()
        let actual = session.mediaService?.media.summary
        XCTAssertEqual(actual?.percentageAdTime, 50)
    }
    
    func testSummary_DoesNotCalculateOrSetValues_WhenMediaSummaryNil() {
        session = SummaryMediaSession(with: mockMediaService)
        session.play()
        session.startChapter(Chapter(name: "Chapter 1", duration: 30))
        session.startAdBreak(AdBreak())
        session.startAd(Ad())
        session.skipAd()
        session.startAd(Ad())
        session.endAdBreak()
        session.skipChapter()
        session.startChapter(Chapter(name: "Chapter 2", duration: 30))
        session.pause()
        session.play()
        session.stop()
        session.endSession()
        session.setSummaryInfo()
        let actual = session.mediaService?.media.summary
        XCTAssertNil(actual?.sessionStartTime)
        XCTAssertNil(actual?.duration)
        XCTAssertNil(actual?.sessionEndTime)
        XCTAssertNil(actual?.percentageChapterComplete)
        XCTAssertNil(actual?.percentageAdComplete)
        XCTAssertNil(actual?.percentageAdTime)
    }
    
    func testEndSession_CallsTrack() {
        session = SummaryMediaSession(with: mockMediaService)
        session.startSession()
        session.endSession()
        XCTAssertEqual(mockMediaService.standardEventCounts[.sessionEnd], 1)
    }
    
    func testSummaryEndSession_ExpectedVariablesInTrack() {
        let expect = expectation(description: "testSummary_ExpectedVariablesInTrack")
        
        let mockModuleDelegate = MockModuleDelegate()
        mockModuleDelegate.asyncExpectation = expect
        session.mediaService!.media.summary = Summary(sessionStartTime: "testStartTime", plays: 1, pauses: 2, adSkips: 2, chapterSkips: 3, stops: 1, ads: 3, totalPlayTime: 30000, totalAdTime: 1500, totalBufferTime: 100, totalSeekTime: 300, adUUIDs: ["uuid1", "uuid2", "uuid3"], playToEnd: true, duration: 40000, percentageAdTime: nil, percentageAdComplete: nil, percentageChapterComplete: 100.0, sessionEndTime: "testEndTime", sessionStart: TimeTraveler().travel(by: -40000), sessionEnd: TimeTraveler().travel(by: -1), playStartTime: TimeTraveler().travel(by: -30500), bufferStartTime: nil, seekStartTime: nil, adStartTime: TimeTraveler().travel(by: -3000), chapterStarts: 5, chapterEnds: 5, adEnds: 2)
        session = SummaryMediaSession(with: MediaEventService(media: session.mediaService!.media,
                                                              delegate: mockModuleDelegate))
        
        session.endSession()
            
        XCTAssertNotNil(mockModuleDelegate.mediaData?["media_session_start_time"])
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_plays"] as! Int, 1)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_pauses"] as! Int, 2)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_ad_skips"] as! Int, 2)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_chapter_skips"] as! Int, 3)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_stops"] as! Int, 1)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_ads"] as! Int, 3)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_ad_uuids"] as! [String], ["uuid1", "uuid2", "uuid3"])
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_played_to_end"] as! Bool, true)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_play_time"] as! Int, 30000)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_ad_time"] as! Int, 1500)
        XCTAssertNotNil(mockModuleDelegate.mediaData?["media_percentage_ad_time"])
        XCTAssertNotNil(mockModuleDelegate.mediaData?["media_percentage_ad_complete"])
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_percentage_chapter_complete"] as! Double, 100.0)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_buffer_time"] as! Int, 100)
        XCTAssertEqual(mockModuleDelegate.mediaData?["media_total_seek_time"] as! Int, 300)
        XCTAssertNotNil(mockModuleDelegate.mediaData?["media_session_end_time"])
        
        wait(for: [expect], timeout: 1.0)
    }
    
    // MARK: Track
    func testSegment_AdBreakVariables_ToDictionary() {
        let adBreak = AdBreak(title: "Ad Break Vars",
                              id: "xyz123",
                              duration: 90,
                              index: 0,
                              position: 1)
        let segment = Segment.adBreak(adBreak)
        
        XCTAssertNotNil(segment.dictionary?["media_ad_break_uuid"] as! String)
        XCTAssertEqual(segment.dictionary?["media_ad_break_title"] as! String, "Ad Break Vars")
        XCTAssertEqual(segment.dictionary?["media_ad_break_id"] as! String, "xyz123")
        XCTAssertEqual(segment.dictionary?["media_ad_break_length"] as! Int, 90)
        XCTAssertEqual(segment.dictionary?["media_ad_break_index"] as! Int, 0)
        XCTAssertEqual(segment.dictionary?["media_ad_break_position"] as! Int, 1)
    }
    
    func testSegment_AdVariables_ToDictionary() {
        let ad = Ad(name: "Ad Vars",
                    id: "Abc123",
                    duration: 30,
                    position: 1,
                    advertiser: "google",
                    creativeId: "test123",
                    campaignId: "camp123",
                    placementId: "place123",
                    siteId: "site123",
                    creativeUrl: "https://creative.com",
                    numberOfLoads: 1,
                    pod: "ad pod",
                    playerName: "some ad player")
        let segment = Segment.ad(ad)
        
        XCTAssertNotNil(segment.dictionary?["media_ad_uuid"] as! String)
        XCTAssertEqual(segment.dictionary?["media_ad_name"] as! String, "Ad Vars")
        XCTAssertEqual(segment.dictionary?["media_ad_length"] as! Int, 30)
        XCTAssertEqual(segment.dictionary?["media_advertiser"] as! String, "google")
        XCTAssertEqual(segment.dictionary?["media_ad_creative_id"] as! String, "test123")
        XCTAssertEqual(segment.dictionary?["media_ad_campaign_id"] as! String, "camp123")
        XCTAssertEqual(segment.dictionary?["media_ad_placement_id"] as! String, "place123")
        XCTAssertEqual(segment.dictionary?["media_ad_site_id"] as! String, "site123")
        XCTAssertEqual(segment.dictionary?["media_ad_creative_url"] as! String, "https://creative.com")
        XCTAssertEqual(segment.dictionary?["media_ad_load"] as! Int, 1)
        XCTAssertEqual(segment.dictionary?["media_ad_pod"] as! String, "ad pod")
        XCTAssertEqual(segment.dictionary?["media_ad_player_name"] as! String, "some ad player")
    }
    
    func testSegment_ChapterVariables_ToDictionary() {
        let chapter = Chapter(name: "Chapter Vars",
                              duration: 2000,
                              position: 1,
                              startTime: Date(),
                              metadata: ["chapter_meta_key": "chapter_meta_value"])
        let segment = Segment.chapter(chapter)

        XCTAssertEqual(segment.dictionary?["media_chapter_name"] as! String, "Chapter Vars")
        XCTAssertEqual(segment.dictionary?["media_chapter_length"] as! Int, 2000)
        XCTAssertEqual(segment.dictionary?["media_chapter_position"] as! Int, 1)
        XCTAssertNotNil(segment.dictionary?["media_chapter_start_time"])
        XCTAssertNotNil(segment.dictionary?["media_chapter_metadata"])
    }
    
    func testMediaSessionData_AddedToMediaRequestData() {
        session.mediaService?.media = MediaContent(name: "Media Vars",
                                                   streamType: .podcast,
                                                   mediaType: .audio,
                                                   qoe: QoE(bitrate: 5000,
                                                            startTime: 123,
                                                            fps: 456,
                                                            droppedFrames: 7,
                                                            playbackSpeed: 1.25,
                                                            metadata: ["custom_qoe_meta_key": "custom_qoe_meta_val"]),
                                                   trackingType: .significant,
                                                   state: .mute,
                                                   customId: "some id",
                                                   duration: 3000,
                                                   playerName: "some player",
                                                   channelName: "some channel",
                                                   metadata: ["custom_meta_key": "custom_meta_val",
                                                              "author": "bob"])
        
        let trackRequest = TealiumMediaEvent(event: .event(.sessionStart),
                                             parameters: session.mediaService!.media)
        
            XCTAssertNotNil(trackRequest.data["media_uuid"])
            XCTAssertEqual(trackRequest.data["media_name"] as! String, "Media Vars")
            XCTAssertEqual(trackRequest.data["media_stream_type"] as! String, "podcast")
            XCTAssertEqual(trackRequest.data["media_type"] as! String, "audio")
            XCTAssertEqual(trackRequest.data["media_tracking_type"] as! String, "significant")
            XCTAssertEqual(trackRequest.data["media_player_state"] as! String, "mute")
            XCTAssertEqual(trackRequest.data["media_custom_id"] as! String, "some id")
            XCTAssertEqual(trackRequest.data["media_length"] as! Int, 3000)
            XCTAssertEqual(trackRequest.data["media_player_name"] as! String, "some player")
            XCTAssertEqual(trackRequest.data["media_channel_name"] as! String, "some channel")
            XCTAssertEqual(trackRequest.data["media_qoe_bitrate"] as! Int, 5000)
            XCTAssertEqual(trackRequest.data["media_qoe_startup_time"] as! Int, 123)
            XCTAssertEqual(trackRequest.data["media_qoe_frames_per_second"] as! Int, 456)
            XCTAssertEqual(trackRequest.data["media_qoe_dropped_frames"] as! Int, 7)
            XCTAssertEqual(trackRequest.data["media_qoe_playback_speed"] as! Double, 1.25)
            XCTAssertEqual(trackRequest.data["custom_qoe_meta_key"] as! String, "custom_qoe_meta_val")
            XCTAssertEqual(trackRequest.data["custom_meta_key"] as! String, "custom_meta_val")
            XCTAssertEqual(trackRequest.data["author"] as! String, "bob")
    }
    
    func testSegmentVariables_AddedToMediaRequestData() {
        let chapter = Chapter(name: "Chapter Vars",
                              duration: 2000,
                              position: 1,
                              startTime: Date(),
                              metadata: ["chapter_meta_key": "chapter_meta_value"])
        let trackRequest = TealiumMediaEvent(event: .event(.chapterEnd),
                                             parameters: session.mediaService!.media,
                                             segment: .chapter(chapter))
        XCTAssertEqual(trackRequest.data["media_chapter_name"] as! String, "Chapter Vars")
        XCTAssertEqual(trackRequest.data["media_chapter_length"] as! Int, 2000)
        XCTAssertEqual(trackRequest.data["media_chapter_position"] as! Int, 1)
        XCTAssertNotNil(trackRequest.data["media_chapter_start_time"])
        XCTAssertEqual(trackRequest.data["chapter_meta_key"] as! String, "chapter_meta_value")
    }
    
    func testCustomEventName_AddedToTrackRequest() {
        let mediaRequest = TealiumMediaEvent(event: .custom("some_custom_media_event"),
                                             parameters: session.mediaService!.media,
                                             segment: nil)
        XCTAssertEqual(mediaRequest.data["tealium_event"] as! String, "some_custom_media_event")
        XCTAssertEqual(mediaRequest.trackRequest.trackDictionary["tealium_event"] as! String, "some_custom_media_event")
    }
    
    func testSegmentMetaVariables_OverwriteMediaSessionVariables() {
        session.mediaService?.media.metadata = ["song": "song value 1",
                                                "artist": "artist value 1",
                                                "album": "album 1"]
        let chapter = Chapter(name: "Chapter Vars",
                              duration: 2000,
                              position: 1,
                              startTime: Date(),
                              metadata: ["song": "song value 2", "artist": "artist value 2"])
        let trackRequest = TealiumMediaEvent(event: .event(.chapterStart),
                                             parameters: session.mediaService!.media,
                                             segment: .chapter(chapter))
        XCTAssertEqual(trackRequest.data["song"] as! String, "song value 2")
        XCTAssertEqual(trackRequest.data["artist"] as! String, "artist value 2")
        XCTAssertEqual(trackRequest.data["album"] as! String, "album 1")
    }
    
    func testTrackMethod_CallsDelegateRequestTrack() {
        let expect = expectation(description: "testTrackMethod_CallsDelegateRequestTrack")
        
        let mockModuleDelegate = MockModuleDelegate()
        mockModuleDelegate.asyncExpectation = expect
        
        session.mediaService = MediaEventService(media: session.mediaService!.media, delegate: mockModuleDelegate)
        session.mediaService?.track(.event(.sessionStart))
        
        wait(for: [expect], timeout: 1.0)
    }
    
    func testTrackMethod_CallsDelegateRequestTrackAndSetsData() {
        let expect = expectation(description: "testTrackMethod_CallsDelegateRequestTrackAndSetsData")
        
        let mockModuleDelegate = MockModuleDelegate()
        mockModuleDelegate.asyncExpectation = expect
        
        session.mediaService?.media.metadata = ["song": "song value 1",
                                                "artist": "artist value 1",
                                                "album": "album 1"]
        session.mediaService = MediaEventService(media: session.mediaService!.media, delegate: mockModuleDelegate)
        
        let chapter = Chapter(name: "Chapter Vars",
                              duration: 2000,
                              position: 1,
                              startTime: Date(),
                              metadata: ["song": "song value 2", "artist": "artist value 2"])
        
        session.mediaService?.track(
            .event(.chapterStart),
            .chapter(chapter)
        )
            
        XCTAssertEqual(mockModuleDelegate.mediaData?["song"] as! String, "song value 2")
        XCTAssertEqual(mockModuleDelegate.mediaData?["artist"] as! String, "artist value 2")
        XCTAssertEqual(mockModuleDelegate.mediaData?["album"] as! String, "album 1")
        
        wait(for: [expect], timeout: 1.0)
    }
    
    func testEventSequence_CallsTrack_InCorrectOrder() {
        session.startSession()
        session.startAdBreak(AdBreak(title: "AdBreak 1"))
        session.startAd(Ad(name: "Ad 1"))
        session.endAd()
        session.endAdBreak()
        session.play()
        session.startChapter(Chapter(name: "Chapter 1", duration: 60))
        session.pause()
        session.play()
        session.endChapter()
        session.stop()
        session.endSession()
        
        let expectedSequence: [StandardMediaEvent] = [.sessionStart,
                                                      .adBreakStart,
                                                      .adStart,
                                                      .adEnd,
                                                      .adBreakEnd,
                                                      .play,
                                                      .chapterStart,
                                                      .pause,
                                                      .play,
                                                      .chapterEnd,
                                                      .stop,
                                                      .sessionEnd]
        
        mockMediaService.eventSequence.enumerated().forEach {
            let index = $0.offset
            let element = $0.element
            XCTAssertEqual(element, expectedSequence[index])
        }
        
    }
    
    // MARK: Extensions Tests
    func testMediaServiceNotNilWhenAddedToCollectors() {
        let expect = expectation(description: "testMediaServiceNotNilWhenAddedToCollectors")
        let config = TealiumConfig(account: "account", profile: "profile", environment: "env")
        config.collectors = [Collectors.Media]
        tealium = Tealium(config: config) { _ in
            XCTAssertNotNil(self.tealium?.media)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func testMediaServiceNilWhenAddedToCollectors() {
        let expect = expectation(description: "testMediaServiceNotNilWhenAddedToCollectors")
        let config = TealiumConfig(account: "account", profile: "profile", environment: "env")
        tealium = Tealium(config: config) { _ in
            XCTAssertNil(self.tealium?.media)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

}

class MockModuleDelegate: ModuleDelegate {
    
    var mediaData: [String: Any]?
    var asyncExpectation: XCTestExpectation?
    
    func requestTrack(_ track: TealiumTrackRequest) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockModuleDelegate was not setup correctly. Missing XCTestExpectation reference")
            return
        }
        mediaData = track.trackDictionary
        expectation.fulfill()
    }
    
    func requestDequeue(reason: String) {}
    func processRemoteCommandRequest(_ request: TealiumRequest) {}
}
