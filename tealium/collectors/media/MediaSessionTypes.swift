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

class SignificantEventMediaSession: SignificantEventMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    init(with mediaService: MediaEventDispatcher) {
        self.mediaService = mediaService
    }
}

class HeartbeatMediaSession: HeartbeatMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    init(with mediaService: MediaEventDispatcher) {
        self.mediaService = mediaService
    }
    
    func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    func abandon() {
        
    }
}

class MilestoneMediaSession: MilestoneMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    init(with mediaService: MediaEventDispatcher) {
        self.mediaService = mediaService
    }
    
    func milestone() {
        mediaService?.track(.event(.milestone))
    }
    
}

// TODO: need more details
class SummaryMediaSession: SummaryMediaProtocol {
    var mediaService: MediaEventDispatcher?
    
    init(with mediaService: MediaEventDispatcher) {
        self.mediaService = mediaService
    }
    
    func update(summary: Summary) {
        print("MEDIA: update summary")
    }
    
    func summary() {
        print("MEDIA: send summary")
        // name, duration,
    }
}
