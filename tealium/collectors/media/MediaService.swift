//
//  MediaService.swift
//  TealiumCore
//
//  Created by Christina S on 1/6/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation



// config.addMediaSession(MediaSessionProtocol)
// media.add(MediaSessionProtocol)
// media.remove(MediaSessionProtocol)
// media.removeAll()


// Abstract MediaSessionFactory -> HeartBeat, Signifigant, Milestone, Summary
// Create Audio/Video Codable objects - decodeIfPresent from optional meta data


enum StreamType { }
enum MediaType { }
enum TrackingType {
    case heartbeat, signifigant, milestone, summary
}
struct QOE: Codable { }

protocol MediaService {
    var media: TealiumMedia { get set }
    func play()
    func pause()
    func stop()
}

extension MediaService {
    func play() {
        // default implementation
    }
    func pause() {
        // default implementation
    }
    func stop() {
        // default implementation
    }
}

struct TealiumMedia {
    var name: String
    var streamType: StreamType
    var mediaType: MediaType
    var qoe: QOE
    var trackingType: TrackingType? = .signifigant
}

struct MediaServiceFactory {
    static func create(_ type: TrackingType, from media: TealiumMedia) -> MediaService {
        switch type {
        case .signifigant:
            return Signifigant(media: media)
        case .heartbeat:
            return Heartbeat(media: media)
        case .milestone:
            return Milestone(media: media)
        case .summary:
            return Summary(media: media)
        }
    }
}

protocol SignifigantEventMediaService: MediaService {
    
}

protocol HeartbeatMediaService: MediaService {
    func ping()
}

protocol MilestoneMediaService: MediaService {
    func milestone()
}

protocol SummaryMediaService: MediaService {
    var summary: SummaryInfo { get set }
}

// might change to class
struct Signifigant: SignifigantEventMediaService {
    var media: TealiumMedia
    
}

// might change to class
struct Heartbeat: HeartbeatMediaService {
    
    var media: TealiumMedia
    
    func ping() {
        // track ping
    }
}

// might change to class
struct Milestone: MilestoneMediaService {
    
    var media: TealiumMedia
    
    func milestone() {
        // track milestone
    }
    
}

// might change to class (update
struct Summary: SummaryMediaService {
    var media: TealiumMedia
    var summary: SummaryInfo {
        get {
            // update
            try! Disk.retrieve("", from: .documents, as: SummaryInfo.self)
        }
        set {
            // update
            try! Disk.save(newValue, to: .documents, as: "")
        }
    }
}


struct SummaryInfo: Codable {
    var plays: Int = 0
    var pauses: Int = 0
    var stops: Int = 0
    var ads: Int = 0
    var chapters: Int = 0
}
