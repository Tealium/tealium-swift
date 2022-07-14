//
//  MilestoneMediaTrackingPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 07/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

open class MediaSessionPingPlugin {
    public var bag = TealiumDisposeBag()
    private var timer: Repeater
    public init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, timer: Repeater) {
        self.timer = timer
        self.timer.eventHandler = self.pingHandler
        dataProvider.state.observeNew(\.playback) { [weak self] state in
            switch state {
            case .playing:
                self?.timer.resume()
            default:
                self?.timer.suspend()
                self?.onSuspend(for: state)
            }
        }.toDisposeBag(bag)
        events.onEndSession.subscribe { [weak self] in
            self?.timer.suspend()
        }.toDisposeBag(bag)
    }

    open func pingHandler() {

    }

    open func onSuspend(for state: MediaSessionState.PlaybackState) {

    }

    func calculatePercentage(playhead: Double, duration: Int) -> Double {
        let duration = Double(duration)
        return max(min(((playhead / duration) * 100).rounded(.up), 100), 0)
    }
}

public struct MilestonePluginOptions {
    let timer: Repeater

    public init(interval: Double) {
        self.init(timer: TealiumRepeatingTimer(timeInterval: interval,
                                               dispatchQueue: TealiumQueues.backgroundSerialQueue))
    }

    init(timer: Repeater) {
        self.timer = timer
    }
}

public class MilestoneMediaTrackingPlugin: MediaSessionPingPlugin, MediaSessionPlugin, TrackingPluginFactoryWithOptions {
    public typealias Options = MilestonePluginOptions
    let dataProvider: MediaSessionDataProvider
    let tracker: MediaTracker

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        MilestoneMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        self.dataProvider = dataProvider
        self.tracker = tracker
        super.init(dataProvider: dataProvider, events: events, timer: options.timer)
    }

    private func sendMilestone(_ milestone: Milestone) {
        guard dataProvider.dataLayer["media_milestone"] as? String != milestone.rawValue else { return }
        dataProvider.dataLayer["media_milestone"] = milestone.rawValue
        tracker.requestTrack(.event(.milestone))
    }

    public override func pingHandler() {
        guard let playhead = dataProvider.delegate?.getPlayhead(),
              let duration = dataProvider.state.mediaMetadata.duration else { return }
        let percentage = calculatePercentage(playhead: playhead,
                                             duration: duration)
        switch percentage {
        case 10 ..< 25:
            sendMilestone(.ten)
        case 25 ..< 50:
            sendMilestone(.twentyFive)
        case 50 ..< 75:
            sendMilestone(.fifty)
        case 75 ..< 90:
            sendMilestone(.seventyFive)
        case 90 ..< 100:
            sendMilestone(.ninety)
        case 100:
            sendMilestone(.oneHundred)
        default:
            break
        }
    }

    public override func onSuspend(for state: MediaSessionState.PlaybackState) {
        pingHandler()
    }
}
