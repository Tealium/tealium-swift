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
    
    private var timer: Repeater
    
    init(with mediaService: MediaEventDispatcher,
         _ timer: Repeater? = nil) {
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: 10.0)
        super.init(with: mediaService)
    }
    
    /// Sends a heartbeat event
    override func ping() {
        mediaService?.track(.event(.heartbeat))
    }
    
    /// Cancels the heartbeat timer
    override func stopPing() {
        timer.suspend()
    }
    
    /// Sends a `play` event and defines the timer event handler to be triggered every
    /// 10 seconds
    override func play() {
        super.play()
        timer.eventHandler = { [weak self] in
            self?.ping()
        }
        timer.resume()
    }
    
    override func pause() {
        super.pause()
        timer.suspend()
    }
    
    override func stop() {
        super.stop()
        timer.suspend()
    }
    
    /// Sends an `endSession` event and cancel the timer
    override func endSession() {
        super.endSession()
        timer.suspend()
    }
    
    deinit {
        timer.suspend()
    }

}

class HeartbeatMilestoneMediaSession: MilestoneMediaSession {
    
    /// Adds a heartbeat ping every 10 seconds to the milestone tracking type
    override func ping() {
        if difference % 10 == 0 {
            mediaService?.track(.event(.heartbeat))
        }
        super.ping()
    }
    
}

class MilestoneMediaSession: MediaSession {
    
    private var timer: Repeater
    private var duration: Int?
    private var startTime: Date?
    private var previousDifference = 0
    private var timeElapsed = 0
    private var triggered = [Milestone]()
    
    init(with mediaService: MediaEventDispatcher,
         interval: Double,
         _ timer: Repeater? = nil) {
        self.duration = mediaService.media.duration
        self.startTime = mediaService.media.startTime
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: interval)
        super.init(with: mediaService)
    }
    
    /// Difference, in seconds between the start of the playback and current playback position
    var difference: Int {
        calculate(duration: startTime) ?? 0
    }
    
    /// Checks the current playback against the provided duration for the percentage played
    /// If within range of a milestone, set the `media_milestone` and send an event
    override func ping() {
        timeElapsed = difference + previousDifference
        var currentMilestone: Milestone?
        switch percentage {
        case 8.0...12.0:
            currentMilestone = setMilestoneOnce(.ten)
        case 23.0...27.0:
            currentMilestone = setMilestoneOnce(.twentyFive)
        case 48.0...52.0:
            currentMilestone = setMilestoneOnce(.fifty)
        case 73.0...77.0:
            currentMilestone = setMilestoneOnce(.seventyFive)
        case 88.0...92.0:
            currentMilestone = setMilestoneOnce(.ninty)
        case 97.0...100:
            currentMilestone = setMilestoneOnce(.oneHundred)
        default:
            return
        }
        guard let current = currentMilestone else {
            return
        }
        sendMilestone(current)
    }
    
    override func startSession() {
        triggered = [Milestone]()
        super.startSession()
    }
    
    /// Sends a `play` event and define timer event handler to be triggered for given interval
    override func play() {
        startTime = Date()
        timer.eventHandler = { [weak self] in
            self?.ping()
        }
        timer.resume()
        super.play()
    }
    
    /// Sends a `pause` event and records the time elapsed thus far
    override func pause() {
        timer.suspend()
        previousDifference += difference
        super.pause()
    }

    override func stop() {
        timer.suspend()
        super.stop()
    }
    
    /// Cancels the milestone timer
    override func stopPing() {
        timer.suspend()
    }
    
    /// Sends an `endSession` event and cancel the timer
    override func endSession() {
        timer.suspend()
        super.endSession()
    }

    /// Sets `media_milestone` and sends event
    override func sendMilestone(_ milestone: Milestone) {
        mediaService?.media.milestone = milestone.rawValue
        mediaService?.track(.event(.milestone))
    }
    
    private func setMilestoneOnce(_ milestone: Milestone) -> Milestone? {
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
        return Double(timeElapsed) / Double(duration) * 100
    }
    
    deinit {
        timer.suspend()
    }
    
}

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
    
    /// Instantiates the `Summary` upon the start of the session
    override func startSession() {
        mediaService?.media.summary = Summary()
    }
    
    /// Increments the playcount and sets the latetest play start time
    override func play() {
        mediaService?.media.summary?.plays.increment()
        mediaService?.media.summary?.playStartTime = Date()
    }
    
    /// Increments chapter start
    override func startChapter(_ chapter: Chapter) {
        mediaService?.media.summary?.chapterStarts.increment()
    }
    
    /// Increments chapter skip
    override func skipChapter() {
        mediaService?.media.summary?.chapterSkips.increment()
    }
    
    /// Increments chapter end
    override func endChapter() {
        mediaService?.media.summary?.chapterEnds.increment()
    }
    
    /// Sets latest buffer start time
    override func startBuffer() {
        mediaService?.media.summary?.bufferStartTime = Date()
    }
    
    /// Increments total buffer time
    override func endBuffer() {
        guard let startTime = mediaService?.media.summary?.bufferStartTime,
              let bufferDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalBufferTime.increment(by: bufferDuration)
    }
    
    /// Sets latest seek start time
    override func startSeek() {
        mediaService?.media.summary?.seekStartTime = Date()
    }
    
    /// Increments total seek time
    override func endSeek() {
        guard let startTime = mediaService?.media.summary?.seekStartTime,
              let seekDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.totalSeekTime.increment(by: seekDuration)
    }
    
    /// Increments ad count, adds uuid to adUUIDs, sets the latest ad start time
    override func startAd(_ ad: Ad) {
        mediaService?.media.summary?.ads.increment()
        mediaService?.media.summary?.adUUIDs.append(ad.uuid)
        mediaService?.media.summary?.adStartTime = Date()
    }
    
    /// Increments total ad play time and ad skips
    override func skipAd() {
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.adSkips.increment()
        mediaService?.media.summary?.totalAdTime.increment(by: adPlayDuration)
    }
    
    /// Increments total ad play time and ad ends
    override func endAd() {
        guard let startTime = mediaService?.media.summary?.adStartTime,
              let adPlayDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.adEnds.increment()
        mediaService?.media.summary?.totalAdTime.increment(by: adPlayDuration)
    }
    
    /// Increments pause count and total play time
    override func pause() {
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.pauses.increment()
        mediaService?.media.summary?.totalPlayTime.increment(by: playDuration)
    }
    
    /// Increments stop count and total play time
    override func stop() {
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.stops.increment()
        mediaService?.media.summary?.totalPlayTime.increment(by: playDuration)
    }
    
    /// Calculates `Summary` properties based on session counters
    override func setSummaryInfo() {
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
    
    /// Sets session end time, sets summary variables, and ends session
    override func endSession() {
        mediaService?.media.summary?.sessionEnd = Date()
        mediaService?.media.summary?.playToEnd = true
        setSummaryInfo()
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

