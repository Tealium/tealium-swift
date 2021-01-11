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

public protocol MediaSession {
    var delegate: ModuleDelegate? { get set }
    // var delegate: SummaryDelegate? { get set }
    var media: TealiumMedia { get set }
}

public extension MediaSession {
    
    var bitrate: Int {
        get { media.qoe.bitrate }
        set {
            track(.event(.bitrateChange))
            media.qoe.bitrate = newValue
        }
    }
    
    var droppedFrames: Int {
        get { media.qoe.droppedFrames ?? 0 }
        set {
            media.qoe.droppedFrames = newValue
        }
    }
    
    var playbackSpeed: Double {
        get { media.qoe.playbackSpeed ?? 1.0 }
        set {
            media.qoe.playbackSpeed = newValue
        }
    }
    
    var playerState: PlayerState? {
        get { media.state }
        set {
            if media.state == nil {
                media.state = newValue
                track(.event(.playerStateStart))
            } else if media.state != newValue {
                track(.event(.playerStateStop))
                media.state = newValue
                track(.event(.playerStateStart))
            }
        }
    }
    
    func adBreakEnd() {
        track(.event(.adBreakEnd))
    }
    
    func adBreakStart(_ adBreak: AdBreak) {
        // track(.event(.adBreakStart), adBreak)
        /* OR */
        track(
            .event(.adBreakStart),
            .segment(
                .adBreak(adBreak)
            )
        )
        
    }
    
    func adClick() {
        track(.event(.adClick))
    }
    
    func adComplete() {
        track(.event(.adComplete))
    }
    
    func adSkip() {
        track(.event(.adSkip))
    }
    
    func adStart(_ ad: Ad) {
        // track(.event(.adStart), ad)
        /* OR */
        track(
            .event(.adStart),
            .segment(
                .ad(ad)
            )
        )
    }
    
    func bufferEnd() {
        track(.event(.bufferEnd))
    }
    
    func bufferStart() {
        track(.event(.seekStart))
    }
    
    func chapterComplete() {
        track(.event(.chapterComplete))
    }
    
    func chapterSkip() {
        track(.event(.chapterSkip))
    }
    
    func chapterStart(_ chapter: Chapter) {
        // track(.event(.chapterStart), chapter)
        /* OR */
        track(
            .event(.chapterStart),
            .segment(
                .chapter(chapter)
            )
        )
    }
    
    func close() {
        track(.event(.complete))
    }
    
    func seek() {
        track(.event(.seekStart))
    }
    
    func seekComplete() {
        track(.event(.seekComplete))
    }
    
    func start() {
        track(.event(.start))
    }
    
    func play() {
        track(.event(.play))
    }
    func pause() {
        track(.event(.pause))
    }
    func stop() {
        track(.event(.stop))
    }
    
    func track(_ event: MediaEvent,
               _ segment: Segment? = nil) {
        let mediaEvent = TealiumMediaEvent(event: event,
                                           parameters: media,
                                           segment: segment)
        delegate?.requestTrack(mediaEvent.trackRequest)
    }
}

public struct MediaSessionFactory {
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
