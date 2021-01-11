//
//  MediaSessionModels.swift
//  tealium-swift
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
// #if media
import TealiumCore
// #endif

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
    case heartbeat
    case milestone
    case signifigant
    case summary
}

public enum PlayerState: String, Codable {
    case closedCaption
    case fullscreen
    case inFocus
    case mute
    case pictureInPicture
}

// TODO: need more details
public struct Summary: Codable {
    var plays: Int = 0
    var pauses: Int = 0
    var stops: Int = 0
    var ads: Int = 0
    var chapters: Int = 0
}

public protocol Segmentable: Codable { }

public enum Segment {
    case segment(SegmentNode)
    
    var dictionary: [String: Any] {
        switch self {
        case .segment(let type):
            return type.dictionary ?? [String: Any]()
        }
    }
    
}

public enum SegmentNode {
    case chapter(Chapter)
    case adBreak(AdBreak)
    case ad(Ad)
    
    var dictionary: [String: Any]? {
        switch self {
        case .chapter(let chapter):
            return chapter.dictionary
        case .ad(let ad):
            return ad.dictionary
        case .adBreak(let adBreak):
            return adBreak.dictionary
        }
    }
}

public enum StandardMediaEvent: String {
    case adBreakEnd = "media_adbreak_complete"
    case adBreakStart = "media_adbreak_start"
    case adClick = "media_ad_click"
    case adComplete = "media_ad_complete"
    case adSkip = "media_ad_skip"
    case adStart = "media_ad_start"
    case bitrateChange = "media_bitrate_change" // *
    case bufferEnd = "media_buffer_end"  // *
    case bufferStart = "media_buffer_start"  // *
    case chapterComplete = "media_chapter_complete"
    case chapterSkip = "media_chapter_skip"
    case chapterStart = "media_chapter_start"
    case complete = "media_session_complete" // *
    case custom = "custom_media_event" // *
    case heartbeat = "media_heartbeat"
    case milestone = "media_milestone"
    case pause = "media_pause" // *
    case play = "media_play" // *
    case playerStateStart = "player_state_start" // *
    case playerStateStop = "player_state_stop" // *
    case seekStart = "media_seek_start"  // *
    case seekComplete = "media_seek_complete"  // *
    case start = "media_session_start" // *
    case stop = "media_stop" // *
    case summary = "media_summary"
}

public enum MediaEvent {
    case event(StandardMediaEvent)
    case custom(String)
}

public struct Audio: Codable {}
public struct Video: Codable {}

public struct TealiumMedia: Codable {
    var uuid = UUID().uuidString
    var name: String
    var streamType: StreamType
    var mediaType: MediaType
    var qoe: QOE
    var trackingType: TrackingType
    //var contentMetaData: AnyCodable?
    var state: PlayerState?
    var customId: String?
    var duration: Int?
    var playerName: String?
    var channelName: String?
    var metadata: [String: AnyCodable]?
    var milestone: String?
    var summary: Summary?
    
    enum CodingKeys: String, CodingKey {
        case uuid = "media_uuid"
        case name = "media_name"
        case streamType = "media_stream_type"
        case mediaType = "media_type"
        case qoe = "media_qoe"
        case trackingType = "media_tracking_interval"
        case state = "media_player_state"
        case customId = "media_custom_id"
        case duration = "media_length"
        case playerName = "media_player_name"
        case channelName = "media_channel_name"
        case metadata = "media_metadata"
        case milestone = "media_milestone"
        case summary = "media_summary"
    }
    
    public init(
        name: String,
        streamType: StreamType,
        mediaType: MediaType,
        qoe: QOE,
        trackingType: TrackingType = .signifigant,
        state: PlayerState? = nil,
        customId: String? = nil,
        duration: Int? = nil,
        playerName: String? = nil,
        channelName: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
            self.name = name
            self.streamType = streamType
            self.mediaType = mediaType
            self.qoe = qoe
            self.trackingType = trackingType
            self.customId = customId
            self.duration = duration
            self.playerName = playerName
            self.channelName = channelName
            self.metadata = metadata
    }

}

public struct QOE: Codable {
    var bitrate: Int
    var startTime: Int?
    var fps: Int?
    var droppedFrames: Int?
    var playbackSpeed: Double?
    var metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case bitrate
        case startTime = "media_qoe_startup_time"
        case fps = "media_qoe_frames_per_second"
        case droppedFrames = "media_qoe_dropped_frames"
        case playbackSpeed = "media_qoe_playback_speed"
        case metadata = "media_qoe_metadata"
    }
    
    public init(bitrate: Int,
                startTime: Int? = nil,
                fps: Int? = nil,
                droppedFrames: Int? = nil) {
        self.bitrate = bitrate
        self.startTime = startTime
        self.fps = fps
        self.droppedFrames = droppedFrames
    }
}

// TODO: Increment position
public struct Chapter: Segmentable {
    var name: String
    var duration: Int
    var position: Int?
    var startTime: Int?
    var metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case name = "chapter_name"
        case duration = "chapter_length"
        case position = "chapter_position"
        case startTime = "chapter_start_time"
        case metadata = "chapter_metadata"
    }
    
    public init(name: String,
                duration: Int,
                position: Int? = nil,
                startTime: Int? = nil,
                metadata: [String: AnyCodable]? = nil) {
        self.name = name
        self.duration = duration
        self.position = position
        self.startTime = startTime
        self.metadata = metadata
    }
}

// TODO: Increment position and calculate values
public struct Ad: Segmentable {
    var uuid = UUID().uuidString
    var name: String? // need to calculate "Ad Break 1"
    var id: String?
    var duration: Int? // need to calculate
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
    
    enum CodingKeys: String, CodingKey {
        case uuid = "ad_uuid"
        case name = "ad_name"
        case id = "ad_id"
        case duration = "ad_length"
        case position = "ad_position"
        case advertiser = "advertiser"
        case creativeId = "ad_creative_id"
        case campaignId = "ad_campaign_id"
        case placementId = "ad_placement_id"
        case siteId = "ad_site_id"
        case creativeUrl = "ad_creative_url"
        case numberOfLoads = "ad_load"
        case pod = "ad_pod"
        case playerName = "ad_player_name"
    }
    
    public init(name: String,
                id: String? = nil,
                duration: Int? = nil,
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
        self.name = name
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

// TODO: Increment position and calculate values
public struct AdBreak: Segmentable {
    var uuid = UUID().uuidString
    var title: String?
    var id: Int?
    // need to calculate
    var duration: Int?
    var index: Int?
    var position: Int?
    var numberOfAdBreaks = 0
    
    enum CodingKeys: String, CodingKey {
        case uuid = "ad_break_uuid"
        case title = "ad_break_name"
        case id = "ad_break_id"
        case duration = "ad_break_length"
        case index = "ad_break_index"
        case position = "ad_break_position"
    }
    
    public init(title: String? = nil,
                id: Int? = nil,
                duration: Int? = nil, // need to calculate
                index: Int? = nil,
                position: Int? = nil) {
        increment()
        self.title = title ?? "Ad Break \(numberOfAdBreaks)"
        self.id = id
        self.duration = duration
        self.index = index
        self.position = position // use counter
    }
    
    private mutating func increment() {
        numberOfAdBreaks += 1
    }
}
