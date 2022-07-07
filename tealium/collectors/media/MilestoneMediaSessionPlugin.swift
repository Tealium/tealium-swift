//
//  MilestoneMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 07/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

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

public class MilestoneMediaSessionPlugin: MediaSessionPlugin, PluginFactoryWithOptions {
    public typealias Options = MilestonePluginOptions
    private var bag = TealiumDisposeBag()
    let dataProvider: MediaSessionDataProvider
    let tracker: MediaTracker
    var timer: Repeater

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        MilestoneMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        self.dataProvider = dataProvider
        self.tracker = tracker
        self.timer = options.timer
        timer.eventHandler = { [weak self] in
            self?.checkPlayheadMilestone()
        }
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        return [
            events.onPlaybackStateChange.subscribe { [weak self] state in
                switch state {
                case .playing:
                    self?.startPing()
                default:
                    self?.stopPing()
                    self?.checkPlayheadMilestone()
                }
            },
            events.onEndSession.subscribe { [weak self] in
                self?.stopPing()
            }
        ]
    }

    private func sendMilestone(_ milestone: Milestone) {
        guard dataProvider.dataLayer["media_milestone"] as? String != milestone.rawValue else { return }
        dataProvider.dataLayer["media_milestone"] = milestone.rawValue
        tracker.requestTrack(.event(.milestone))
    }

    private func startPing() {
        timer.resume()
    }

    private func stopPing() {
        timer.suspend()
    }

    private func checkPlayheadMilestone() {
        guard let playhead = dataProvider.delegate?.getPlayhead(),
              let duration = dataProvider.mediaMetadata.duration else { return }
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
}

private func calculatePercentage(playhead: Double, duration: Int) -> Double {
    let duration = Double(duration)
    return max(min(((playhead / duration) * 100).rounded(.up), 100), 0)
}
