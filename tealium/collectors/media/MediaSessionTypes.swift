//
//  MediaSessionTypes.swift
//  tealium-swift
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
    import TealiumCore
//#endif

protocol SignifigantEventMediaProtocol: MediaSession { }

protocol HeartbeatMediaProtocol: MediaSession {
    func ping()
}

protocol MilestoneMediaProtocol: MediaSession {
    func milestone()
}

protocol SummaryMediaProtocol: MediaSession {
    //var summary: Summary { get set }
    func update(summary: Summary)
    func summary()
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
        track(.event(.heartbeat))
    }
}

// might change to class
struct MilestoneMediaSession: MilestoneMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func milestone() {
        track(.event(.milestone))
    }
    
}

//public protocol SummaryDelegate {
//    func update(summary: SummaryInfo)
//}

// TODO: need more details
struct SummaryMediaSession: SummaryMediaProtocol {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func update(summary: Summary) {
        print("MEDIA: update summary")
    }
    
    func summary() {
        print("MEDIA: send summary")
    }
}
