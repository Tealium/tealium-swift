//
//  EarlyEndContentMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 07/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public struct EarlyEndContentPluginOptions {
    let percentageToComplete: Double
    let timer: Repeater

    public init(percentageToComplete: Double, interval: Double) {
        self.init(percentageToComplete: percentageToComplete,
                  timer: TealiumRepeatingTimer(timeInterval: interval,
                                               dispatchQueue: TealiumQueues.backgroundSerialQueue))
    }

    init(percentageToComplete: Double, timer: Repeater) {
        self.percentageToComplete = percentageToComplete
        self.timer = timer
    }
}

public class EarlyEndContentMediaSessionPlugin: MediaSessionPlugin, PluginFactoryWithOptions {
    public typealias Options = EarlyEndContentPluginOptions
    private var bag = TealiumDisposeBag()
    let dataProvider: MediaSessionDataProvider
    let tracker: MediaTracker
    let options: Options
    var timer: Repeater

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        EarlyEndContentMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        self.dataProvider = dataProvider
        self.options = options
        self.tracker = tracker
        timer = options.timer
        timer.eventHandler = { [weak self] in
            self?.checkPlayheadContentEnded()
        }
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        [
            events.onPlaybackStateChange.subscribe { [weak self] state in
                switch state {
                case .playing:
                    self?.timer.resume()
                case .paused:
                    self?.timer.suspend()
                case .ended:
                    self?.contentEnded()
                default:
                    break
                }
            },
            events.onEndSession.subscribe(timer.suspend)
        ]
    }

    private func contentEnded() {
        timer.suspend()
        bag.dispose()
        tracker.requestTrack(.event(.contentEnd))
    }

    private func checkPlayheadContentEnded() {
        guard let playhead = dataProvider.delegate?.getPlayhead(),
              let duration = dataProvider.mediaMetadata.duration else { return }
        let percentage = calculatePercentage(playhead: playhead,
                                             duration: duration)
        if percentage >= options.percentageToComplete {
            contentEnded()
        }
    }
}

private func calculatePercentage(playhead: Double, duration: Int) -> Double {
    let duration = Double(duration)
    return max(min(((playhead / duration) * 100).rounded(.up), 100), 0)
}
