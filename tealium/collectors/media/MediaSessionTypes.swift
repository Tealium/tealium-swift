//
//  MediaSessionTypes.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

class SignificantEventMediaSession: MediaSession { }

class HeartbeatMediaSession: MediaSession {
    
    var heartbeatTimer: Repeater?
    
    init(with mediaService: MediaEventDispatcher,
         _ timer: Repeater? = nil) {
        self.heartbeatTimer = timer ?? TealiumRepeatingTimer(timeInterval: 10.0)
        super.init(with: mediaService)
    }
    
    
//    func abandon() {
//        /* Potentially use “Abandonment Indicators” patent to figure out when the best time is to send an event; how likely is the user to abandon? */
//    }
    
    override func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    override func stopPing() {
        heartbeatTimer?.suspend()
    }
    
    override func startSession() {
        super.startSession()
        heartbeatTimer?.eventHandler = { [weak self] in
            self?.ping()
        }
        heartbeatTimer?.resume()
    }
    
    override func endSession() {
        super.endSession()
        heartbeatTimer?.suspend()
    }
    
    deinit {
        heartbeatTimer?.suspend()
    }

}

class MilestoneMediaSession: MediaSession {

    override func milestone(_ milestone: Milestone) {
        mediaService?.media.milestone = milestone.rawValue
        mediaService?.track(.event(.milestone))
    }
    
}

// TODO: need more details
class SummaryMediaSession: MediaSession {
    
    override func startSession() {
        mediaService?.media.summary = Summary()
    }
    
    override func play() {
        mediaService?.media.summary?.plays.increment()
        mediaService?.media.summary?.playStartTime = Date()
    }
    
    override func startChapter(_ chapter: Chapter) {
        mediaService?.media.summary?.chapterStarts.increment()
    }
    
    override func skipChapter() {
        mediaService?.media.summary?.chapterSkips.increment()
        mediaService?.media.summary?.chapterEnds.increment()
    }
    
    override func endChapter() {
        mediaService?.media.summary?.chapterEnds.increment()
    }
    
    override func startBuffer() {
        mediaService?.media.summary?.bufferStartTime = Date()
    }
    
    override func endBuffer() {
        guard let startTime = mediaService?.media.summary?.bufferStartTime,
              let bufferDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalBufferTime?.increment(by: bufferDuration)
    }
    
    override func startSeek() {
        mediaService?.media.summary?.seekStartTime = Date()
    }
    
    override func endSeek() {
        guard let startTime = mediaService?.media.summary?.seekStartTime,
              let seekDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalSeekTime?.increment(by: seekDuration)
    }
    
    override func startAd(_ ad: Ad) {
        mediaService?.media.summary?.ads.increment()
        mediaService?.media.summary?.adUUIDs.append(ad.uuid)
        mediaService?.media.summary?.adStartTime = Date()
    }
    
    override func skipAd() {
        mediaService?.media.summary?.adSkips.increment()
        mediaService?.media.summary?.adEnds.increment()
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalAdTime?.increment(by: adPlayDuration)
    }
    
    override func endAd() {
        mediaService?.media.summary?.adEnds.increment()
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalAdTime?.increment(by: adPlayDuration)
    }
    
    override func pause() {
        mediaService?.media.summary?.pauses.increment()
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalPlayTime?.increment(by: playDuration)
    }
    
    override func stop() {
        mediaService?.media.summary?.stops.increment()
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalPlayTime?.increment(by: playDuration)
    }
    
    override func summary() {
        guard let summary = mediaService?.media.summary else {
            return
        }
        mediaService?.media.summary?.sessionStartTime = summary.sessionStart.iso8601String
        mediaService?.media.summary?.duration = calculate(duration: summary.sessionStart)
        mediaService?.media.summary?.sessionEndTime = summary.sessionEnd?.iso8601String
        mediaService?.media.summary?.percentageChapterComplete = Double(summary.chapterEnds / summary.chapterStarts)
        mediaService?.media.summary?.percentageAdTime = Double(summary.adEnds / summary.ads)
        guard let totalPlayTime = summary.totalPlayTime,
           let totalAdTime = summary.totalAdTime else {
            return
        }
        mediaService?.media.summary?.percentageAdTime = Double(totalPlayTime / totalAdTime)
    }
    
    override func endSession() {
        mediaService?.media.summary?.sessionEnd = Date()
        mediaService?.media.summary?.playToEnd = true
        summary()
        super.endSession()
    }
    
    override func startAdBreak(_ adBreak: AdBreak) { }
    override func endAdBreak() { }
    override func clickAd() { }
    override func custom(_ event: String) { }

}

