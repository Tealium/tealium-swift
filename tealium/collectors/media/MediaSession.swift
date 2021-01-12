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

// Do we send all the adBreak data on adBreakEnd? If not, how do we calculate duration?
// Same w adEnd
// What other metrics to calculate?
// should all the "completes" be Complete or End?
// Should we use session.close() or session.complete?

public protocol MediaSession {
//    var bitrate: Int { get set}
//    var droppedFrames: Int { get set }
//    var playbackSpeed: Double { get set }
//    var playerState: PlayerState? { get set }
    var delegate: ModuleDelegate? { get set }
    // var delegate: SummaryDelegate? { get set }
    var media: TealiumMedia { get set }
    
    func track(_ event: MediaEvent,
               _ segment: Segment?) // make private?
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
    
    mutating func adBreakEnd() {
        guard var adBreak = media.adBreaks?.first else {
            return
        }
        adBreak.duration = calculate(duration: adBreak.startTime)
        track(
            .event(.adBreakEnd),
            .adBreak(adBreak)
        )
        media.adBreaks?.removeFirst(1)
    }
    
    mutating func adBreakStart(_ adBreak: AdBreak) {
         media.adBreaks?.append(adBreak)
        // track(.event(.adBreakStart), adBreak)
        /* OR */
        track(
            .event(.adBreakStart),
            .adBreak(adBreak)
        )
        
    }
    
    func adClick() {
        track(.event(.adClick))
    }
    
    mutating func adComplete() {
        guard var ad = media.ads?.first else {
            return
        }
        ad.duration = calculate(duration: ad.startTime)
        track(.event(.adComplete))
        media.ads?.removeFirst(1)
    }
    
    func adSkip() {
        track(.event(.adSkip))
    }
    
    mutating func adStart(_ ad: Ad) {
        media.ads?.append(ad)
        // track(.event(.adStart), ad)
        /* OR */
        track(
            .event(.adStart),
            .ad(ad)
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
            .chapter(chapter)
        )
    }
    
    func close() {
        track(.event(.complete))
    }
    
    func custom(_ event: String) {
        track(.custom(event))
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
    
    private func calculate(duration: Date) -> Int? {
        let duration = Calendar.current.dateComponents([.second],
                                                       from: duration,
                                                       to: Date())
        return duration.second
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

// Might need this for tests
public protocol MediaSessionEvents {
    func adBreakEnd()
    func adBreakStart(_ adBreak: AdBreak)
    func adClick()
    func adComplete()
    func adSkip()
    func adStart(_ ad: Ad)
    func bitrateChange()
    func bufferEnd()
    func bufferStart()
    func chapterComplete()
    func chapterSkip()
    func chapterStart(_ chapter: Chapter)
    func close()
    func custom(_ event: String)
    func heartbeat()
    func milestone()
    func pause()
    func play()
    func playerStateStart()
    func playerStateStop()
    func seekStart()
    func seekComplete()
    func start()
    func stop()
    func summary()
}
