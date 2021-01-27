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
    
    var timer: Repeater
    
    init(with mediaService: MediaEventDispatcher,
         _ timer: Repeater? = nil) {
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: 10.0)
        super.init(with: mediaService)
    }
    
    override func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    override func stopPing() {
        timer.suspend()
    }
    
    override func startSession() {
        super.startSession()
        timer.eventHandler = { [weak self] in
            self?.ping()
        }
        timer.resume()
    }
    
    override func endSession() {
        super.endSession()
        timer.suspend()
    }
    
    deinit {
        timer.suspend()
    }

}

class HeartbeatMilestoneMediaSession: MilestoneMediaSession {
    
    override func ping() {
        if difference % 10 == 0 {
            mediaService?.track(.event(.heartbeat))
        }
        super.ping()
    }
    
}

class MilestoneMediaSession: MediaSession {
    
    private var timer: Repeater
    private var duration: Double?
    private var startTime: Date?
    private var triggered = [Milestone]()
    
    init(with mediaService: MediaEventDispatcher,
         interval: Double,
         _ timer: Repeater? = nil) {
        self.duration = mediaService.media.duration
        self.startTime = mediaService.media.startTime
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: interval)
        super.init(with: mediaService)
    }
    
    var difference: Int {
        calculate(duration: startTime) ?? 0
    }
    
    override func ping() {
        var currentMilestone: Milestone?
        switch percentage {
        case 8.0...12.0:
            currentMilestone = unique(.ten)
        case 23.0...27.0:
            currentMilestone = unique(.twentyFive)
        case 48.0...52.0:
            currentMilestone = unique(.fifty)
        case 73.0...77.0:
            currentMilestone = unique(.seventyFive)
        case 88.0...92.0:
            currentMilestone = unique(.ninty)
        case 97.0...100:
            currentMilestone = unique(.oneHundred)
        default:
            return
        }
        guard let current = currentMilestone else {
            return
        }
        milestone(current)
    }
    
    override func startSession() {
        super.startSession()
        startTime = Date()
        timer.eventHandler = { [weak self] in
            self?.ping()
        }
        timer.resume()
    }
    
    override func stopPing() {
        timer.suspend()
    }
    
    override func endSession() {
        super.endSession()
        timer.suspend()
    }

    override func milestone(_ milestone: Milestone) {
        mediaService?.media.milestone = milestone.rawValue
        mediaService?.track(.event(.milestone))
    }
    
    private func unique(_ milestone: Milestone) -> Milestone? {
        guard !triggered.contains(milestone) else {
            return nil
        }
        triggered.append(milestone)
        return milestone
    }
    
    private var percentage: Double {
        guard let duration = duration else {
            return 0.0
        }
        return Double(difference) / Double(duration) * 100
    }
    
    deinit {
        timer.suspend()
    }
    
}

// TODO: need more details
class SummaryMediaSession: MediaSession {
    
    override var bitrate: Int? {
        get { mediaService?.media.qoe.bitrate }
        set {
            if let newValue = newValue {
                mediaService?.media.qoe.bitrate = newValue
            }
        }
    }
    
    override var playerState: PlayerState? {
        get { mediaService?.media.state }
        set { mediaService?.media.state = newValue }
    }
    
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
        mediaService?.media.summary?.totalBufferTime.increment(by: bufferDuration)
    }
    
    override func startSeek() {
        mediaService?.media.summary?.seekStartTime = Date()
    }
    
    override func endSeek() {
        guard let startTime = mediaService?.media.summary?.seekStartTime,
              let seekDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalSeekTime.increment(by: seekDuration)
    }
    
    override func startAd(_ ad: Ad) {
        mediaService?.media.summary?.ads.increment()
        mediaService?.media.summary?.adUUIDs.append(ad.uuid)
        mediaService?.media.summary?.adStartTime = Date()
    }
    
    override func skipAd() {
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.adSkips.increment()
        mediaService?.media.summary?.totalAdTime.increment(by: adPlayDuration)
    }
    
    override func endAd() {
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.adEnds.increment()
        mediaService?.media.summary?.totalAdTime.increment(by: adPlayDuration)
    }
    
    override func pause() {
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.pauses.increment()
        mediaService?.media.summary?.totalPlayTime.increment(by: playDuration)
    }
    
    override func stop() {
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.stops.increment()
        mediaService?.media.summary?.totalPlayTime.increment(by: playDuration)
    }
    
    override func summary() {
        guard let summary = mediaService?.media.summary else {
            return
        }
        mediaService?.media.summary?.sessionStartTime = summary.sessionStart.iso8601String
        mediaService?.media.summary?.duration = calculate(duration: summary.sessionStart)
        mediaService?.media.summary?.sessionEndTime = summary.sessionEnd?.iso8601String
        if summary.chapterStarts > 0 {
            mediaService?.media.summary?.percentageChapterComplete = divide(summary.chapterEnds,
                                                                            by: summary.chapterStarts) * 100
        }
        if summary.ads > 0 {
            mediaService?.media.summary?.percentageAdComplete = divide(summary.adEnds,
                                                                       by: summary.ads) * 100
        }
        if summary.totalAdTime > 0 {
            mediaService?.media.summary?.percentageAdTime = divide(summary.totalAdTime,
                                                                   by: summary.totalPlayTime) * 100
        }
    }
    
    override func endSession() {
        mediaService?.media.summary?.sessionEnd = Date()
        mediaService?.media.summary?.playToEnd = true
        summary()
        super.endSession()
    }
    
    override func startAdBreak(_ adBreak: AdBreak) {
        return
    }
    
    override func endAdBreak() {
        return
    }
    
    override func clickAd() {
        return
    }
    
    private func divide(_ a: Int, by b: Int) -> Double {
        return Double(a) / Double(b)
    }

}

