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

    override func setUpWithError() throws {
        session = SignificantEventMediaSession(mediaService: mockMediaService)
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
        
        let session = module.createSession(from: TealiumMedia(name: "test", streamType: .aod, mediaType: .video, qoe: QOE(bitrate: 1000)))
        
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
        
        session.mediaService?.media.trackingType = .summary
        let summary = MediaSessionFactory.create(from: session.mediaService!.media, with: MockModuleDelegate())
        guard let _ = summary as? SummaryMediaSession else {
            XCTFail("Incorrect Type Created in Factory")
            return
        }
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
    
    func testAdBreakStart_UUIDGenerated() {
        session.adBreakStart(AdBreak())
        XCTAssertNotNil(session.mediaService!.media.adBreaks.first!.uuid)
    }
    
    func testAdBreakComplete_Called() {
        session.mediaService?.media.adBreaks = [AdBreak()]
        session.adBreakComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakComplete], 1)
    }
    
    func testAdBreakComplete_NotCalled_WhenNoAdStart() {
        session.adBreakComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adBreakComplete], 0)
    }
    
    func testAdBreakComplete_DurationSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(duration: 60)]
        session.adBreakComplete()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.duration, 60)
        default:
            break
        }
    }
    
    func testAdBreakComplete_DurationCalculated_WhenNotDefined() {
        session.mediaService?.media.adBreaks = [AdBreak()]
        session.adBreakComplete()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertNotNil(adBreak.duration)
        default:
            break
        }
    }
    
    func testAdBreakComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(position: 2)]
        session.adBreakComplete()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.position, 2)
        default:
            break
        }
    }
    
    func testAdBreakComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(), AdBreak()]
        session.adBreakComplete()
        switch mockMediaService.updatedSegment {
        case .adBreak(let adBreak): XCTAssertEqual(adBreak.position, 1)
        default:
            break
        }
    }
    
    func testAdBreakComplete_AdBreakDataIsCorrect() {
        let adBreak = AdBreak(title: "Test Ad Break Complete", id: "abc123", duration: 120, index: 1, position: 2)
        session.mediaService?.media.adBreaks = [adBreak]
        session.adBreakComplete()
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
    
    func testAdStart_UUIDGenerated() {
        session.adStart(Ad())
        XCTAssertNotNil(session.mediaService!.media.ads.first!.uuid)
    }
    
    func testAdComplete_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.adComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adComplete], 1)
    }
    
    func testAdComplete_adRemovedFromArray() {
        session.mediaService?.media.ads = [Ad()]
        session.adComplete()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testAdComplete_NotCalled_WhenNoAdStart() {
        session.adComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adComplete], 0)
    }
    
    func testAdComplete_DurationSet_WhenDefined() {
        session.mediaService?.media.ads = [Ad(duration: 30)]
        session.adComplete()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.duration, 30)
        default:
            break
        }
    }
    
    func testAdComplete_DurationCalculated_WhenNotDefined() {
        session.mediaService?.media.ads = [Ad()]
        session.adComplete()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertNotNil(ad.duration)
        default:
            break
        }
    }
    
    func testAdComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.adBreaks = [AdBreak(position: 3)]
        session.adComplete()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.position, 3)
        default:
            break
        }
    }
    
    func testAdComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.ads = [Ad(), Ad()]
        session.adComplete()
        switch mockMediaService.updatedSegment {
        case .ad(let ad): XCTAssertEqual(ad.position, 1)
        default:
            break
        }
    }
    
    func testAdComplete_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Complete", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.adSkip()
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
        session.adSkip()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adSkip], 1)
    }
    
    func testAdSkip_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Skip", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.adSkip()
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
        session.adSkip()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testAdSkip_NotCalled_WhenNoAdStart() {
        session.adSkip()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adSkip], 0)
    }
    
    func testAdClick_Called() {
        session.mediaService?.media.ads = [Ad()]
        session.adClick()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adClick], 1)
    }
    
    func testAdClick_NotCalled_WhenNoAdStart() {
        session.adClick()
        XCTAssertEqual(mockMediaService.standardEventCounts[.adClick], 0)
    }
    
    func testAdClick_AdDataIsCorrect() {
        let ad = Ad(name: "Test Ad Click", id: "Abc123", duration: 30, position: 1, advertiser: "google", creativeId: "test123", campaignId: "camp123", placementId: "place123", siteId: "test site id", creativeUrl: "https://creative.com", numberOfLoads: 1, pod: "ad pod", playerName: "some ad player")
        session.mediaService?.media.ads = [ad]
        session.adClick()
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
        session.adClick()
        XCTAssertEqual(session.mediaService!.media.ads.count, 0)
    }
    
    func testChapterStart_Called() {
        session.chapterStart(Chapter(name: "Chapter 1", duration: 900))
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterStart], 1)
    }
    
    func testChapterStart_ChapterAddedToArray() {
        session.chapterStart(Chapter(name: "Chapter 1", duration: 900))
        XCTAssertEqual(session.mediaService!.media.chapters.count, 1)
    }
    
    func testChapterComplete_Called() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.chapterComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterComplete], 1)
    }
    
    func testChapterComplete_PositionSet_WhenDefined() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900, position: 3)]
        session.chapterComplete()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter): XCTAssertEqual(chapter.position, 3)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
    
    func testChapterComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900), Chapter(name: "Chapter 2", duration: 960)]
        session.chapterComplete()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter): XCTAssertEqual(chapter.position, 1)
        default:
            XCTFail("Incorrect segment type")
            break
        }
    }
        
    func testChapterComplete_ChapterDataIsCorrect() {
        let chapter = Chapter(name: "Test Chapter Complete", duration: 960, position: 1, startTime: Date(), metadata: ["chapter_meta_key": "chapter_meta_value"])
        session.mediaService?.media.chapters = [chapter]
        session.chapterComplete()
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
        session.chapterComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterComplete], 0)
    }
        
    func testChapterComplete_ChapterRemovedFromArray() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.chapterComplete()
        XCTAssertEqual(session.mediaService!.media.chapters.count, 0)
    }
    
    func testChapterSkip_Called() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900)]
        session.chapterSkip()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterSkip], 1)
    }
        
    func testChapterSkip_ChapterDataIsCorrect() {
        let chapter = Chapter(name: "Test Chapter Skip", duration: 960, position: 1, startTime: Date(), metadata: ["chapter_meta_key": "chapter_meta_value"])
        session.mediaService?.media.chapters = [chapter]
        session.chapterSkip()
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
        session.chapterSkip()
        XCTAssertEqual(session.mediaService!.media.chapters.count, 0)
    }
    
    func testChapterSkip_NotCalled_WhenNoChapterStart() {
        session.chapterSkip()
        XCTAssertEqual(mockMediaService.standardEventCounts[.chapterSkip], 0)
    }
    
    func testSeekStart_Called() {
        session.seek()
        XCTAssertEqual(mockMediaService.standardEventCounts[.seekStart], 1)
    }
    
    func testSeekComplete_Called() {
        session.seekComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.seekComplete], 1)
    }
    
    func testBufferStart_Called() {
        session.bufferStart()
        XCTAssertEqual(mockMediaService.standardEventCounts[.bufferStart], 1)
    }
    
    func testBufferComplete_Called() {
        session.bufferComplete()
        XCTAssertEqual(mockMediaService.standardEventCounts[.bufferComplete], 1)
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
        session.start()
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
        session.close()
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
    
    // TODO:
    func testPing_Called() { }
    func testMilestone_Called() { }
    func testSummary_Called() { }
    func testSummary_Updated_OnMediaEvent() { }
    
    // MARK: Tracking Types
    func testSignificantEvents_TrackingType_DoesNotSendHeartbeat() {
        session.start()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.heartbeat], 0)
    }
    
    func testSignificantEvents_TrackingType_DoesNotSendMilestone() {
        session.start()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.milestone], 0)
    }
    
    func testSignificantEvents_TrackingType_DoesNotSendSummary() {
        session.start()
        session.play()
        session.stop()
        XCTAssertEqual(mockMediaService.standardEventCounts[.summary], 0)
    }
    
    // TODO:
    func testHeartbeat_SentEveryTenSeconds() { }
    func testMilestones_Sent() { }
    func testSummary_Sent() { }
    
    // MARK: Track
    func testSegment_AdBreakVariables_ToDictionary() {
        let adBreak = AdBreak(title: "Ad Break Vars",
                              id: "xyz123",
                              duration: 90,
                              index: 0,
                              position: 1)
        let segment = Segment.adBreak(adBreak)
        
        XCTAssertNotNil(segment.dictionary?["ad_break_uuid"] as! String)
        XCTAssertEqual(segment.dictionary?["ad_break_title"] as! String, "Ad Break Vars")
        XCTAssertEqual(segment.dictionary?["ad_break_id"] as! String, "xyz123")
        XCTAssertEqual(segment.dictionary?["ad_break_length"] as! Int, 90)
        XCTAssertEqual(segment.dictionary?["ad_break_index"] as! Int, 0)
        XCTAssertEqual(segment.dictionary?["ad_break_position"] as! Int, 1)
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
        
        XCTAssertNotNil(segment.dictionary?["ad_uuid"] as! String)
        XCTAssertEqual(segment.dictionary?["ad_name"] as! String, "Ad Vars")
        XCTAssertEqual(segment.dictionary?["ad_length"] as! Int, 30)
        XCTAssertEqual(segment.dictionary?["advertiser"] as! String, "google")
        XCTAssertEqual(segment.dictionary?["ad_creative_id"] as! String, "test123")
        XCTAssertEqual(segment.dictionary?["ad_campaign_id"] as! String, "camp123")
        XCTAssertEqual(segment.dictionary?["ad_placement_id"] as! String, "place123")
        XCTAssertEqual(segment.dictionary?["ad_site_id"] as! String, "site123")
        XCTAssertEqual(segment.dictionary?["ad_creative_url"] as! String, "https://creative.com")
        XCTAssertEqual(segment.dictionary?["ad_load"] as! Int, 1)
        XCTAssertEqual(segment.dictionary?["ad_pod"] as! String, "ad pod")
        XCTAssertEqual(segment.dictionary?["ad_player_name"] as! String, "some ad player")
    }
    
    func testSegment_ChapterVariables_ToDictionary() {
        let chapter = Chapter(name: "Chapter Vars",
                              duration: 2000,
                              position: 1,
                              startTime: Date(),
                              metadata: ["chapter_meta_key": "chapter_meta_value"])
        let segment = Segment.chapter(chapter)

        XCTAssertEqual(segment.dictionary?["chapter_name"] as! String, "Chapter Vars")
        XCTAssertEqual(segment.dictionary?["chapter_length"] as! Int, 2000)
        XCTAssertEqual(segment.dictionary?["chapter_position"] as! Int, 1)
        XCTAssertNotNil(segment.dictionary?["chapter_start_time"])
        XCTAssertNotNil(segment.dictionary?["chapter_metadata"])
    }
    
    func testMediaSessionData_AddedToMediaRequestData() {
        session.mediaService?.media = TealiumMedia(name: "Media Vars",
                                                   streamType: .podcast,
                                                   mediaType: .audio,
                                                   qoe: QOE(bitrate: 5000,
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
            XCTAssertEqual(trackRequest.data["media_tracking_interval"] as! String, "significant")
            XCTAssertEqual(trackRequest.data["media_player_state"] as! String, "mute")
            XCTAssertEqual(trackRequest.data["media_custom_id"] as! String, "some id")
            XCTAssertEqual(trackRequest.data["media_length"] as! Int, 3000)
            XCTAssertEqual(trackRequest.data["media_player_name"] as! String, "some player")
            XCTAssertEqual(trackRequest.data["media_channel_name"] as! String, "some channel")
            XCTAssertEqual(trackRequest.data["qoe_bitrate"] as! Int, 5000)
            XCTAssertEqual(trackRequest.data["qoe_startup_time"] as! Int, 123)
            XCTAssertEqual(trackRequest.data["qoe_frames_per_second"] as! Int, 456)
            XCTAssertEqual(trackRequest.data["qoe_dropped_frames"] as! Int, 7)
        XCTAssertEqual(trackRequest.data["qoe_playback_speed"] as! Double, 1.25)
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
        let trackRequest = TealiumMediaEvent(event: .event(.chapterComplete),
                                             parameters: session.mediaService!.media,
                                             segment: .chapter(chapter))
        XCTAssertEqual(trackRequest.data["chapter_name"] as! String, "Chapter Vars")
        XCTAssertEqual(trackRequest.data["chapter_length"] as! Int, 2000)
        XCTAssertEqual(trackRequest.data["chapter_position"] as! Int, 1)
        XCTAssertNotNil(trackRequest.data["chapter_start_time"])
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
    
    // TODO: Event sequence
    func testMediaSessionPerformance() throws {
        // performance testing
        self.measure { }
    }

}

class MockModuleDelegate: ModuleDelegate {
    
    var mediaData: [String: Any]?
    var asyncExpectation: XCTestExpectation?
    
    func requestTrack(_ track: TealiumTrackRequest) {
        guard let expectation = asyncExpectation else {
            XCTFail("MockModuleDelegate was not setup correctly. Missing XCTExpectation reference")
            return
        }
        mediaData = track.trackDictionary
        expectation.fulfill()
    }
    
    func requestDequeue(reason: String) {}
    func processRemoteCommandRequest(_ request: TealiumRequest) {}
}
