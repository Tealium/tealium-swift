//
//  SummaryMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 28/06/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class SummaryMediaSessionPlugin: MediaSessionPlugin, TrackingPluginFactory {
    private var bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SummaryMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        let builder = SummaryBuilder()
        return [
            dataProvider.state.observeNew(\.playback, changeHandler: builder.playbackStateChange),
            events.onStartChapter.subscribe(builder.startChapter),
            events.onSkipChapter.subscribe(builder.skipChapter),
            events.onEndChapter.subscribe(builder.endChapter),
            events.onStartBuffer.subscribe(builder.startBuffer),
            events.onEndBuffer.subscribe(builder.endBuffer),
            events.onStartSeek.subscribe(builder.startSeek),
            events.onEndSeek.subscribe(builder.endSeek),
            events.onStartAd.subscribe(builder.startAd),
            events.onSkipAd.subscribe(builder.skipAd),
            events.onEndAd.subscribe(builder.endAd),
            events.onEndSession.subscribe {
                builder.endSession()
                tracker.requestTrack(.event(.summary), dataLayer: builder.build().encoded)
            }
        ]
    }
}

class SummaryBuilder {
    private var summary = Summary()

    func playbackStateChange(_ state: MediaSessionState.PlaybackState) {
        switch state {
        case .playing:
            play()
        case .paused:
            pause()
        case .ended:
            endContent()
        case .idle:
            break
        }
    }

    private func play() {
        summary.plays.increment()
        summary.playStartTime = Date()
    }

    func startChapter(_ chapter: Chapter) {
        summary.chapterStarts.increment()
    }

    func skipChapter() {
        summary.chapterSkips.increment()
    }

    func endChapter() {
        summary.chapterEnds.increment()
    }

    func startBuffer() {
        summary.bufferStartTime = Date()
    }

    func endBuffer() {
        guard let bufferDuration = calculate(duration: summary.bufferStartTime) else { return }
        summary.totalBufferTime.increment(by: bufferDuration)
    }

    func startSeek(_ position: Double?) {
        summary.seekStartPosition = position
    }

    func endSeek(_ position: Double?) {
        guard let startPosition = summary.seekStartPosition,
              let endPosition = position else {
            return
        }
        summary.totalSeekTime.increment(by: (endPosition - startPosition))
    }

    func startAd(_ adv: Ad) {
        summary.ads.increment()
        summary.adUUIDs.append(adv.uuid)
        summary.adStartTime = Date()
    }

    func skipAd() {
        guard let adPlayDuration = calculate(duration: summary.adStartTime) else { return }
        summary.adSkips.increment()
        summary.totalAdTime.increment(by: adPlayDuration)
    }

    func endAd() {
        guard let adPlayDuration = calculate(duration: summary.adStartTime) else { return }
        summary.adEnds.increment()
        summary.totalAdTime.increment(by: adPlayDuration)
    }

    private func pause() {
        guard let playDuration = calculate(duration: summary.playStartTime) else { return }
        summary.pauses.increment()
        summary.totalPlayTime.increment(by: playDuration)
    }

    private func endContent() {
        guard let playDuration = calculate(duration: summary.playStartTime) else { return }
        summary.playToEnd = true
        summary.totalPlayTime.increment(by: playDuration)
    }

    func endSession() {
        summary.sessionEnd = Date()
    }

    func build() -> Summary {
        summary.sessionStartTime = summary.sessionStart.iso8601String
        summary.duration = calculate(duration: summary.sessionStart)
        summary.sessionEndTime = summary.sessionEnd?.iso8601String
        if summary.chapterStarts > 0 {
            summary.percentageChapterComplete = divide(summary.chapterEnds,
                                                       rhs: summary.chapterStarts) * 100
        }
        if summary.ads > 0 {
            summary.percentageAdComplete = divide(summary.adEnds,
                                                  rhs: summary.ads) * 100
        }
        if summary.totalAdTime > 0 {
            summary.percentageAdTime = (summary.totalAdTime / summary.totalPlayTime) * 100
        }
        return summary
    }

    /// Calculates the duration of the content, in seconds
    private func calculate(duration: Date?) -> Double? {
        guard let duration = duration else {
            return nil
        }
        let calculated = Calendar.current.dateComponents([.second],
                                                         from: duration,
                                                         to: Date())
        return Double(calculated.second ?? 0)
    }

    private func divide(_ lhs: Int, rhs: Int) -> Double {
        return Double(lhs) / Double(rhs)
    }
}
