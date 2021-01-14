//
//  MediaSessionTypes.swift
//  tealium-swift
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

protocol SignificantEventMediaProtocol: MediaSession { }

protocol HeartbeatMediaProtocol: MediaSession {
    func ping()
}

protocol MilestoneMediaProtocol: MediaSession {
    func milestone()
}

protocol SummaryMediaProtocol: MediaSession {
    func update(summary: Summary)
    func summary()
}

struct SignificantEventMediaSession: SignificantEventMediaProtocol {
    var mediaService: MediaEventDispatcher?
}

struct HeartbeatMediaSession: HeartbeatMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    func abandon() {
        
    }
}

struct MilestoneMediaSession: MilestoneMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    func milestone() {
        mediaService?.track(.event(.milestone))
    }
    
}

// TODO: need more details
struct SummaryMediaSession: SummaryMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    func update(summary: Summary) {
        print("MEDIA: update summary")
    }
    
    func summary() {
        print("MEDIA: send summary")
        // name, duration,
    }
}
