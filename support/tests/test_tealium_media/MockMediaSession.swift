//
//  MockMediaSession.swift
//  TealiumCore
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
@testable import TealiumMedia

class MockMediaService: MediaEventDispatcher {
    var delegate: ModuleDelegate?
    private var _mockMedia = MediaCollection(name: "MockTealiumMedia",
                                             streamType: .vod,
                                             mediaType: .video,
                                             qoe: QoE(bitrate: 1000, startTime: nil, fps: 20),
                                             trackingType: .significant,
                                             state: .fullscreen,
                                             customId: "test custom id",
                                             duration: 3000,
                                             playerName: "test player name",
                                             channelName: "test channel name",
                                             metadata: ["meta_key": "meta_value"])
    var updatedSegment: Segment?
    
    var media: MediaCollection {
        get {
            _mockMedia    
        }
        set {
            _mockMedia = newValue
        }
    }
    
    var standardEventCounts: [StandardMediaEvent: Int] = [
        .adBreakComplete: 0,
        .adBreakStart: 0,
        .adClick: 0,
        .adComplete: 0,
        .adSkip: 0,
        .adStart: 0,
        .bitrateChange: 0,
        .bufferComplete: 0,
        .bufferStart: 0,
        .chapterComplete: 0,
        .chapterSkip: 0,
        .chapterStart: 0,
        .sessionEnd: 0,
        .heartbeat: 0,
        .milestone: 0,
        .pause: 0,
        .play: 0,
        .playerStateStart: 0,
        .playerStateStop: 0,
        .seekStart: 0,
        .seekComplete: 0,
        .sessionStart: 0,
        .stop: 0,
        .summary: 0
    ]
    
    var customEvent: (count: Int, name: String) = (0, "")
    
    func track(_ event: MediaEvent) {
        track(event, nil)
    }
        
    func track(_ event: MediaEvent,
               _ segment: Segment?) {
        switch event {
        case .event(let name):
            standardEventCounts[name]! += 1
            updatedSegment = segment
        case .custom(let name):
            customEvent.count += 1
            customEvent.name = name
        }
    }
    
}
