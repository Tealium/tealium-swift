//
//  MediaSessionTypes.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

protocol HeartbeatMediaProtocol: MediaSessionProtocol {
    func ping()
}

protocol MilestoneMediaProtocol: MediaSessionProtocol {
    func milestone()
}

protocol SummaryMediaProtocol: MediaSessionProtocol {
    func update(summary: Summary)
    func summary()
}

class SignificantEventMediaSession: MediaSession { }

class HeartbeatMediaSession: MediaSession, HeartbeatMediaProtocol {

    func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    func abandon() {
        
    }
}

class MilestoneMediaSession: MediaSession, MilestoneMediaProtocol {

    func milestone() {
        mediaService?.track(.event(.milestone))
    }
    
}

// TODO: need more details
class SummaryMediaSession: MediaSession, SummaryMediaProtocol {
    
    func update(summary: Summary) {
        print("MEDIA: update summary")
    }
    
    func summary() {
        print("MEDIA: send summary")
        // name, duration,
    }
}
