//
//  MockMediaSession.swift
//  TealiumCore
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import TealiumMedia

class MockMediaSession: MediaSession {

    
    var adBreakEndCallCount = 0
    var adBreakStartCallCount = 0
    var adClickCallCount = 0
    var adCompleteCallCount = 0
    var adSkipCallCount = 0
    var adStartCallCount = 0
    var bitrateChangeCallCount = 0
    var bufferEndCallCount = 0
    var bufferStartCallCount = 0
    var chapterCompleteCallCount = 0
    var chapterSkipCallCount = 0
    var chapterStartCallCount = 0
    var closeCallCount = 0
    var customEventCallCount = 0
    var heartbeatCallCount = 0
    var milestoneCallCount = 0
    var pauseCallCount = 0
    var playCallCount = 0
    var playerStateStartCallCount = 0
    var playerStateStopCallCount = 0
    var seekStartCallCount = 0
    var seekCompleteCallCount = 0
    var startCallCount = 0
    var stopCallCount = 0
    var summarCallCount = 0
    
    var delegate: ModuleDelegate?
    var media: TealiumMedia {
        get {
            TealiumMedia(name: "MockTealiumMedia",
                         streamType: .vod,
                         mediaType: .video,
                         qoe: QOE(bitrate: 1500, startTime: nil, fps: 20, droppedFrames: 10),
                         trackingType: .signifigant,
                         state: .fullscreen,
                         customId: "test custom id",
                         duration: 3000,
                         playerName: "test player name",
                         channelName: "test channel name",
                         metadata: ["meta_key": "meta_value"])
        }
        set { }
    }
    
    
    
}
