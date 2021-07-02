//
//  MediaSessionModels.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public enum StreamType: String, Codable {
    case aod
    case audiobook
    case custom = "Custom"
    case dvod = "DVoD"
    case live
    case linear
    case podcast
    case radio
    case song
    case ugc = "UGC"
    case vod
}

public enum MediaType: String, Codable {
    case all
    case audio
    case video
}

public enum TrackingType: String, Codable {
    case interval
    case milestone
    case intervalMilestone = "interval_and_milestone"
    case fullPlayback = "full_playback"
    case summary
}

public enum PlayerState: String, Codable {
    case closedCaption
    case fullscreen
    case inFocus
    case mute
    case pictureInPicture
}

public enum Milestone: String, CaseIterable {
    case ten = "10%"
    case twentyFive = "25%"
    case fifty = "50%"
    case seventyFive = "75%"
    case ninety = "90%"
    case oneHundred = "100%"
}

public enum Segment {
    case chapter(Chapter)
    case adBreak(AdBreak)
    case ad(Ad)
    
    var dictionary: [String: Any]? {
        switch self {
        case .chapter(let chapter):
            return chapter.encoded
        case .ad(let ad):
            return ad.encoded
        case .adBreak(let adBreak):
            return adBreak.encoded
        }
    }
}

public enum StandardMediaEvent: String {
    case adBreakEnd = "media_adbreak_end"
    case adBreakStart = "media_adbreak_start"
    case adClick = "media_ad_click"
    case adEnd = "media_ad_end"
    case adSkip = "media_ad_skip"
    case adStart = "media_ad_start"
    case bitrateChange = "media_bitrate_change"
    case bufferEnd = "media_buffer_end"
    case bufferStart = "media_buffer_start"
    case chapterEnd = "media_chapter_end"
    case chapterSkip = "media_chapter_skip"
    case chapterStart = "media_chapter_start"
    case sessionEnd = "media_session_end"
    case interval = "media_interval"
    case milestone = "media_milestone"
    case pause = "media_pause"
    case play = "media_play"
    case playerStateStart = "player_state_start"
    case playerStateStop = "player_state_stop"
    case seekStart = "media_seek_start"
    case seekEnd = "media_seek_end"
    case sessionResume = "media_session_resume"
    case sessionStart = "media_session_start"
    case contentEnd = "media_content_end"
    case summary = "media_summary"
}

public enum MediaEvent {
    case event(StandardMediaEvent)
    case custom(String)
}

public enum MediaContentState {
    case playing
    case notPlaying
}

public struct QoE: Codable {
    var bitrate: Int
    var startTime: Int?
    var fps: Int?
    var droppedFrames: Int?
    var playbackSpeed: Double?
    var metadata: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case bitrate = "media_qoe_bitrate"
        case startTime = "media_qoe_startup_time"
        case fps = "media_qoe_frames_per_second"
        case droppedFrames = "media_qoe_dropped_frames"
        case playbackSpeed = "media_qoe_playback_speed"
        case metadata = "media_qoe_metadata"
    }
    
    public init(bitrate: Int,
                startTime: Int? = nil,
                fps: Int? = nil,
                droppedFrames: Int? = nil,
                playbackSpeed: Double? = nil,
                metadata: AnyCodable? = nil) {
        self.bitrate = bitrate
        self.startTime = startTime
        self.fps = fps
        self.droppedFrames = droppedFrames
        self.playbackSpeed = playbackSpeed
        self.metadata = metadata
    }
}

public struct Chapter: Codable {
    var uuid = UUID().uuidString
    var name: String
    var duration: Double?
    var position: Int?
    var startTime: Date?
    var metadata: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case uuid = "media_chapter_uuid"
        case name = "media_chapter_name"
        case duration = "media_chapter_duration"
        case position = "media_chapter_position"
        case startTime = "media_chapter_start_time"
        case metadata = "media_chapter_metadata"
    }
    
    public init(name: String,
                duration: Double? = nil,
                position: Int? = nil,
                startTime: Date? = Date(),
                metadata: AnyCodable? = nil) {
        self.name = name
        self.duration = duration
        self.position = position
        self.startTime = startTime
        self.metadata = metadata
    }
}

public struct Ad: Codable {
    var uuid = UUID().uuidString
    var name: String?
    var id: String?
    var duration: Double?
    var position: Int?
    var advertiser: String?
    var creativeId: String?
    var campaignId: String?
    var placementId: String?
    var siteId: String?
    var creativeUrl: String?
    var numberOfLoads: Int?
    var pod: String?
    var playerName: String?
    var startTime: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case uuid = "media_ad_uuid"
        case name = "media_ad_name"
        case id = "ad_id"
        case duration = "media_ad_duration"
        case position = "media_ad_position"
        case advertiser = "media_advertiser"
        case creativeId = "media_ad_creative_id"
        case campaignId = "media_ad_campaign_id"
        case placementId = "media_ad_placement_id"
        case siteId = "media_ad_site_id"
        case creativeUrl = "media_ad_creative_url"
        case numberOfLoads = "media_ad_load"
        case pod = "media_ad_pod"
        case playerName = "media_ad_player_name"
    }
    
    public init(name: String? = nil,
                id: String? = nil,
                duration: Double? = nil,
                position: Int? = nil,
                advertiser: String? = nil,
                creativeId: String? = nil,
                campaignId: String? = nil,
                placementId: String? = nil,
                siteId: String? = nil,
                creativeUrl: String? = nil,
                numberOfLoads: Int? = nil,
                pod: String? = nil,
                playerName: String? = nil) {
        self.name = name ?? "Ad \(uuid)"
        self.id = id
        self.duration = duration
        self.position = position
        self.advertiser = advertiser
        self.creativeId = creativeId
        self.campaignId = campaignId
        self.placementId = placementId
        self.siteId = siteId
        self.creativeUrl = creativeUrl
        self.numberOfLoads = numberOfLoads
        self.pod = pod
        self.playerName = playerName
    }
    
}

public struct AdBreak: Codable {
    var uuid = UUID().uuidString
    var name: String?
    var id: String?
    var duration: Double?
    var index: Int?
    var position: Int?
    var startTime: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case uuid = "media_ad_break_uuid"
        case name = "media_ad_break_name"
        case id = "media_ad_break_id"
        case duration = "media_ad_break_duration"
        case index = "media_ad_break_index"
        case position = "media_ad_break_position"
    }
    
    public init(name: String? = nil,
                id: String? = nil,
                duration: Double? = nil,
                index: Int? = nil,
                position: Int? = nil) {
        self.name = name ?? "Ad Break \(uuid)"
        self.id = id
        self.duration = duration
        self.index = index
        self.position = position
    }
    
}

public struct Summary: Codable {
    var sessionStartTime: String?
    var plays = 0
    var pauses = 0
    var adSkips = 0
    var chapterSkips = 0
    var ads = 0
    var totalPlayTime: Double = 0
    var totalAdTime: Double = 0
    var totalBufferTime: Double = 0
    var totalSeekTime: Double = 0
    var adUUIDs = [String]()
    var playToEnd = false
    var duration: Double?
    var percentageAdTime: Double?
    var percentageAdComplete: Double?
    var percentageChapterComplete: Double?
    var sessionEndTime: String?
    
    // Timers and tallies for calculations
    var sessionStart = Date()
    var sessionEnd: Date?
    var playStartTime: Date?
    var bufferStartTime: Date?
    var seekStartPosition: Double?
    var adStartTime: Date?
    var chapterStarts = 0
    var chapterEnds = 0
    var adEnds = 0
    
    
    enum CodingKeys: String, CodingKey {
        case sessionStartTime = "media_session_start_time"
        case plays = "media_total_plays"
        case pauses = "media_total_pauses"
        case adSkips = "media_total_ad_skips"
        case chapterSkips = "media_total_chapter_skips"
        case ads = "media_total_ads"
        case adUUIDs = "media_ad_uuids"
        case playToEnd = "media_played_to_end"
        case duration = "media_session_duration"
        case totalPlayTime = "media_total_play_time"
        case totalAdTime = "media_total_ad_time"
        case percentageAdTime = "media_percentage_ad_time"
        case percentageAdComplete = "media_percentage_ad_complete"
        case percentageChapterComplete = "media_percentage_chapter_complete"
        case totalBufferTime = "media_total_buffer_time"
        case totalSeekTime = "media_total_seek_time"
        case sessionEndTime = "media_session_end_time"
    }

    
}


