//
//  MediaCollection.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

// Need better name
public class MediaCollection: Codable {
    var uuid = UUID().uuidString
    var name: String
    var streamType: StreamType
    var mediaType: MediaType
    var qoe: QOE
    var trackingType: TrackingType
    var state: PlayerState?
    var customId: String?
    var duration: Int?
    var playerName: String?
    var channelName: String?
    var metadata: AnyCodable?
    
    var adBreaks = [AdBreak]()
    var ads = [Ad]()
    var chapters = [Chapter]()
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
        trackingType: TrackingType = .significant,
        state: PlayerState? = nil,
        customId: String? = nil,
        duration: Int? = nil,
        playerName: String? = nil,
        channelName: String? = nil,
        metadata: AnyCodable? = nil
    ) {
            self.name = name
            self.streamType = streamType
            self.mediaType = mediaType
            self.qoe = qoe
            self.trackingType = trackingType
            self.state = state
            self.customId = customId
            self.duration = duration
            self.playerName = playerName
            self.channelName = channelName
            self.metadata = metadata
    }

}

extension MediaCollection {
    
    func add(_ segment: Segment) {
        switch segment {
        case .ad(let ad):
            ads.append(ad)
        case .adBreak(let adBreak):
            adBreaks.append(adBreak)
        case .chapter(let chapter):
            chapters.append(chapter)
        }
    }
    
    func remove(by uuid: String) {
        ads.removeAll(where: { $0.uuid == uuid })
        adBreaks.removeAll(where: { $0.uuid == uuid })
        chapters.removeAll(where: { $0.uuid == uuid })
    }
}
