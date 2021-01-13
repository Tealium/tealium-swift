//
//  TealiumMediaTests.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumMedia

// TODO: Test correct sequence of events

class TealiumMediaTests: XCTestCase {
    
    var session: MediaSession!
    var mockMediaService = MockMediaService()

    override func setUpWithError() throws {
        session = SignifigantEventMediaSession(mediaService: mockMediaService)
    }
    
    override func tearDownWithError() throws { }

    // MARK: Init & Setup
    // TODO:
    
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
            break
        }
    }
    
    func testChapterComplete_PositionCalculated_WhenNotDefined() {
        session.mediaService?.media.chapters = [Chapter(name: "Chapter 1", duration: 900), Chapter(name: "Chapter 2", duration: 960)]
        session.chapterComplete()
        switch mockMediaService.updatedSegment {
        case .chapter(let chapter): XCTAssertEqual(chapter.position, 1)
        default:
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
    
    func testPlayerStateStart_Called() {
        session.mediaService?.media.state = nil
        session.playerState = .closedCaption
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStart], 1)
    }
    
    func testPlayerStateStop_Called() {
        session.mediaService?.media.state = nil
        session.playerState = .closedCaption
        session.playerState = .fullscreen
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStop], 1)
        XCTAssertEqual(mockMediaService.standardEventCounts[.playerStateStart], 2)
    }
    
    func testCustomEvent_Called() {
        session.custom("My Custom Event")
        XCTAssertEqual(mockMediaService.customEvent.count, 1)
    }
    
    func testCustomEvent_NameSet() {
        session.custom("My Custom Event 2")
        XCTAssertEqual(mockMediaService.customEvent.name, "My Custom Event 2")
    }
    
    func testPing_Called() { }
    func testMilestone_Called() { }
    func testSummary_Called() { }
    func testSummary_Updated_OnMediaEvent() { }
    
    // MARK: Tracking Types
    func testSignifigantEvents_TrackingType_DoesNotSendHeartbeat() { }
    func testSignifigantEvents_TrackingType_DoesNotSendMilestone() { }
    func testSignifigantEvents_TrackingType_DoesNotSendSummary() { }
    func testHeartbeat_SentEveryTenSeconds() { }
    func testMilestones_Sent() { }
    func testSummary_Sent() { }
    
    // MARK: Track
    func testMediaVariables_AddedToTrack() { }
    func testMediaMetaVarables_Flattened() { }
    func testAdBreakMetaVariables_AddedToTrack() { }
    func testAdMetaVariables_AddedToTrack() { }
    func testChapterMetaVariables_AddedToTrack() { }
    func testSegmentVariables_ToDictionary() { }
    func testSegmentMetaVariables_OverwriteMediaSessionVariables() { }
    
    // TODO: Event sequence
    
    func testMediaSessionPerformance() throws {
        // performance testing
        self.measure { }
    }

}

