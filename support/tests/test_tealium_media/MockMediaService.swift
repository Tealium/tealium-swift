//
//  MockMediaService.swift
//  TealiumCore
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import TealiumMedia

class MockMediaService: MediaEventDispatcher {
    var delegate: ModuleDelegate?
    private var _mockMedia = MediaContent(name: "MockTealiumMedia",
                                             streamType: .vod,
                                             mediaType: .video,
                                             qoe: QoE(bitrate: 1000, startTime: nil, fps: 20),
                                             trackingType: .fullPlayback,
                                             state: .fullscreen,
                                             customId: "test custom id",
                                             duration: 3000,
                                             playerName: "test player name",
                                             channelName: "test channel name",
                                             metadata: ["meta_key": "meta_value"])
    var updatedSegment: Segment?
    
    var media: MediaContent {
        get {
            _mockMedia    
        }
        set {
            _mockMedia = newValue
        }
    }
    
    var standardEventCounts: [StandardMediaEvent: Int] = [
        .adBreakEnd: 0,
        .adBreakStart: 0,
        .adClick: 0,
        .adEnd: 0,
        .adSkip: 0,
        .adStart: 0,
        .bitrateChange: 0,
        .bufferEnd: 0,
        .bufferStart: 0,
        .chapterEnd: 0,
        .chapterSkip: 0,
        .chapterStart: 0,
        .sessionEnd: 0,
        .interval: 0,
        .milestone: 0,
        .pause: 0,
        .play: 0,
        .playerStateStart: 0,
        .playerStateStop: 0,
        .seekStart: 0,
        .seekEnd: 0,
        .sessionResume: 0,
        .sessionStart: 0,
        .contentEnd: 0,
        .summary: 0
    ]
    
    var customEvent: (count: Int, name: String) = (0, "")
    
    var eventSequence = [StandardMediaEvent]()
    
    func track(_ event: MediaEvent) {
        track(event, nil)
    }
        
    func track(_ event: MediaEvent,
               _ segment: Segment?) {
        switch event {
        case .event(let name):
            eventSequence.append(name)
            standardEventCounts[name]! += 1
            updatedSegment = segment
        case .custom(let name):
            customEvent.count += 1
            customEvent.name = name
        }
    }
    
}

class MockRepeatingTimer: Repeater {
    
    var resumCount = 0
    var suspendCount = 0
    
    var eventHandler: (() -> Void)?
    
    func resume() {
        resumCount += 1
    }
    
    func suspend() {
        suspendCount += 1
    }
    
    
}
