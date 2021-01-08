//
//  MediaService.swift
//  TealiumCore
//
//  Created by Christina S on 1/6/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

// config.addMediaSession(MediaSession)
// media.add(MediaSession)
// media.remove(MediaSession)
// media.removeAll()


// Abstract MediaSessionFactory -> HeartBeat, Signifigant, Milestone, Summary
// Create Audio/Video Codable objects - decodeIfPresent from optional meta data


public enum StreamType: String {
    case vod
    case live
    case linear
    case podcast
    case audiobook
    case aod
    case song
    case radio
    case ugc = "UGC"
    case dvod = "DVoD"
    case custom = "Custom"
}
public enum MediaType: String {
    case all
    case audio
    case video
}
public enum TrackingType: String {
    case heartbeat, signifigant, milestone, summary
}
public struct QOE: Codable {
    var bitrate: Int
    
    public init(bitrate: Int) {
        self.bitrate = bitrate
    }
}

public protocol MediaSession {
    var delegate: ModuleDelegate? { get set }
    // var delegate: SummaryDelegate? { get set }
    var media: TealiumMedia { get set }
    func track(_ event: MediaEvent)
}

public extension MediaSession {
    
    func start() {
        
    }
    
    func play() {
        print("MEDIA: play")
        track(.play)
    }
    func pause() {
        print("MEDIA: pause")
        track(.pause)
    }
    func stop() {
        print("MEDIA: stop")
        track(.stop)
    }

    func track(_ event: MediaEvent) {
        let mediaRequest = TealiumMediaTrackRequest(event: event, parameters: media)
        delegate?.requestTrack(mediaRequest.trackRequest)
    }
}

public struct TealiumMedia {
    var name: String
    var streamType: StreamType
    var mediaType: MediaType
    var qoe: QOE
    var trackingType: TrackingType
    var customId: String?
    var duration: Int?
    var playerName: String?
    var channelName: String?
    var metadata: [String: String]?
    var milestone: String?
    var summary: Summary?
    
    public init(
        name: String,
        streamType: StreamType,
        mediaType: MediaType,
        qoe: QOE,
        trackingType: TrackingType = .signifigant,
        customId: String? = nil,
        duration: Int? = nil,
        playerName: String? = nil,
        channelName: String? = nil,
        metadata: [String: String]? = nil) {
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

struct MediaSessionFactory {
    static func create(from media: TealiumMedia,
                       with delegate: ModuleDelegate?) -> MediaSession {
        switch media.trackingType {
        case .signifigant:
            return SignifigantEventMediaSession(media: media, delegate: delegate)
        case .heartbeat:
            return HeartbeatMediaSession(media: media, delegate: delegate)
        case .milestone:
            return MilestoneMediaSession(media: media, delegate: delegate)
        case .summary:
            return SummaryMediaSession(media: media, delegate: delegate)
        }
    }
}

protocol SignifigantEventMediaProtocol: MediaSession {
    
}

protocol HeartbeatMediaProtocol: MediaSession {
    func ping()
}

protocol MilestoneMediaProtocol: MediaSession {
    func milestone()
}

protocol SummaryMediaProtocol: MediaSession {
    //var summary: SummaryInfo { get set }
    func update(summary: Summary)
}

// might change to class
struct SignifigantEventMediaSession: SignifigantEventMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
}

// might change to class
struct HeartbeatMediaSession: HeartbeatMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func ping() {
        print("MEDIA: ping")
        // track ping
    }
}

// might change to class
struct MilestoneMediaSession: MilestoneMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func milestone() {
        print("MEDIA: milestone")
        // track milestone
    }
    
}

//public protocol SummaryDelegate {
//    func update(summary: SummaryInfo)
//}

// might change to class 
struct SummaryMediaSession: SummaryMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func update(summary: Summary) {
        print("MEDIA: update")
    }
}

public struct Summary: Codable {
    var plays: Int = 0
    var pauses: Int = 0
    var stops: Int = 0
    var ads: Int = 0
    var chapters: Int = 0
}

public struct Chapter {
    public init() { }
}
public struct Ad {
    public init() { }
}
public struct AdBreak {
    public init() { }
}
