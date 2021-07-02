//
//  MediaSessionTypes.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

class FullPlaybackMediaSession: MediaSession { }

class IntervalMediaSession: MediaSession {
    
    private var timer: Repeater
    
    init(with mediaService: MediaEventDispatcher,
         _ timer: Repeater? = nil) {
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: 10.0)
        super.init(with: mediaService)
    }
    
    /// Sends a interval event
    override func ping() {
        mediaService?.track(.event(.interval))
    }
    
    /// Cancels the interval timer
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
    
    override func endContent() {
        super.endContent()
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

class IntervalMilestoneMediaSession: MilestoneMediaSession {
    
    /// Adds a interval ping every 10 seconds to the milestone tracking type
    override func ping() {
        if Int(totalContentPlayed) % 10 == 0  {
            mediaService?.track(.event(.interval))
        }
        super.ping()
    }
    
}

class MilestoneMediaSession: MediaSession {
    
    private var timer: Repeater
    private var duration: Int?
    private var playbackStart: Date?
    private var contentCompletePercentage: Double?
    private var startSeek: Double?
    private var triggered = [Milestone]()
    private var _totalContentPlayed: Double = 0.0
    
    
    init(with mediaService: MediaEventDispatcher,
         interval: Double,
         _ timer: Repeater? = nil) {
        self.duration = mediaService.media.duration
        self.playbackStart = mediaService.media.startTime
        self.contentCompletePercentage = mediaService.media.contentCompletePercentage
        self.timer = timer ?? TealiumRepeatingTimer(timeInterval: interval)
        super.init(with: mediaService)
    }
    
    /// The total amount of content played, in seconds
    var totalContentPlayed: Double {
        get {
            guard let playbackStart = playbackStart else {
                return _totalContentPlayed
            }
            return _totalContentPlayed + Date().timeIntervalSince(playbackStart)
        }
    }
    
    /// Percentage of content played
    private var percentageContentPlayed: Double {
        guard let duration = duration else {
            return 0.0
        }
        return totalContentPlayed / Double(duration) * 100
    }
    
    /// Should send end content event automatically, based on an optional configuration setting
    /// on the `MediaContent` object
    private var shouldSendEndContent: Bool {
        guard let contentCompletePercentage = contentCompletePercentage else {
            return false
        }
        return percentageContentPlayed >= contentCompletePercentage
    }
    
    /// Checks the current playback against the provided duration for the percentage played
    /// If within range of a milestone, set the `media_milestone` and send an event
    override func ping() {
        var currentMilestone: Milestone?
        if shouldSendEndContent {
            endContent()
        }
        switch percentageContentPlayed {
        case 8.0...12.0:
            currentMilestone = setMilestoneOnce(.ten)
        case 23.0...27.0:
            currentMilestone = setMilestoneOnce(.twentyFive)
        case 48.0...52.0:
            currentMilestone = setMilestoneOnce(.fifty)
        case 73.0...77.0:
            currentMilestone = setMilestoneOnce(.seventyFive)
        case 88.0...92.0:
            currentMilestone = setMilestoneOnce(.ninety)
        case 97.0...100.1:
            currentMilestone = setMilestoneOnce(.oneHundred)
        default:
            return
        }
        guard let current = currentMilestone else {
            return
        }
        sendMilestone(current)
    }
    
    /// Sends a `play` event and define timer event handler to be triggered for given interval
    override func play() {
        triggered = [Milestone]()
        timer.eventHandler = { [weak self] in
            self?.ping()
        }
        setContentState(to: .playing)
        super.play()
    }
    
    /// Sends a `pause` event and records the time elapsed thus far
    override func pause() {
        setContentState(to: .notPlaying)
        super.pause()
    }
    
    /// Sets current playing state to `notPlaying`
    override func startAdBreak(_ adBreak: AdBreak) {
        setContentState(to: .notPlaying)
        super.startAdBreak(adBreak)
    }
    
    /// Sets current playing state to `playing`
    override func endAdBreak() {
        setContentState(to: .playing)
        super.endAdBreak()
    }
    
    /// Calls the `startSeek` event and records the seek start time for milestone tracking
    /// Playhead is required for this implementation
    /// - Parameter position: `Double` the playback position, in seconds, since the start of the content
    override func startSeek(at position: Double? = nil) {
        guard let position = position else {
            return
        }
        startSeek = position
        super.startSeek()
    }
    
    /// Calls the `endSeek` event and records the seek start time for milestone tracking
    /// Playhead is required for this implementation
    /// - Parameter position: `Double` the playback position, in seconds, since the start of the content
    override func endSeek(at position: Double? = nil) {
        guard let startSeek = startSeek,
              let endPosition = position else {
            return
        }
        triggered = [Milestone]()
        _totalContentPlayed += (endPosition - startSeek)
        super.endSeek()
    }

    /// Suspends the milestone timer
    override func endContent() {
        timer.suspend()
        super.endContent()
    }
    
    /// Cancels the milestone timer
    override func stopPing() {
        timer.suspend()
    }
    
    /// Sends an `endSession` event and cancel the milestone timer
    override func endSession() {
        _totalContentPlayed = 0.0
        playbackStart = nil
        timer.suspend()
        super.endSession()
    }

    /// Sets `media_milestone` and sends event
    override func sendMilestone(_ milestone: Milestone) {
        mediaService?.media.milestone = milestone.rawValue
        mediaService?.track(.event(.milestone))
    }
    
    /// Toggles the content state in order to accurately keep track of content played and
    /// suspend/resume milestone timer
    private func setContentState(to state: MediaContentState) {
        switch state {
        case .playing:
            if playbackStart == nil {
                playbackStart = Date()
            }
            timer.resume()
        case .notPlaying:
            _totalContentPlayed = _totalContentPlayed + Date().timeIntervalSince(playbackStart ?? Date())
            playbackStart = nil
            timer.suspend()
        }
    }
    
    private func setMilestoneOnce(_ milestone: Milestone) -> Milestone? {
        guard !triggered.contains(milestone) else {
            return nil
        }
        triggered.append(milestone)
        return milestone
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
    
    /// Calls the `startSeek` event and records the seek start time for milestone tracking
    /// Playhead is required for this implementation
    /// - Parameter position: `Int` the playback position, in seconds, since the start of the content
    override func startSeek(at position: Double?) {
        mediaService?.media.summary?.seekStartPosition = position
    }
    
    /// Calls the `endSeek` event and records the seek start time for milestone tracking
    /// Playhead is required for this implementation
    /// - Parameter position: `Int` the playback position, in seconds, since the start of the content
    override func endSeek(at position: Double?) {
        guard let startPosition = mediaService?.media.summary?.seekStartPosition,
              let endPosition = position else {
            return
        }
        mediaService?.media.summary?.totalSeekTime.increment(by: (endPosition - startPosition))
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
    override func endContent() {
        guard let startTime = mediaService?.media.summary?.playStartTime,
              let playDuration = calculate(duration: startTime) else {
            return
        }
        mediaService?.media.summary?.playToEnd = true
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
            mediaService?.media.summary?.percentageAdTime = (summary.totalAdTime / summary.totalPlayTime) * 100
        }
    }
    
    /// Sets session end time, sets summary variables, and ends session
    override func endSession() {
        mediaService?.media.summary?.sessionEnd = Date()
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

