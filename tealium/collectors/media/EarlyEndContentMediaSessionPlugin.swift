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

public struct EndContentPluginOptions {
    let earlyEndContentOptions: EarlyEndContentPluginOptions?

    public init(earlyEndContentOptions: EarlyEndContentPluginOptions? = nil) {
        self.earlyEndContentOptions = nil
    }
}

class EarlyEndContentMediaSessionPlugin: MediaSessionPingPlugin, MediaSessionPlugin, BehaviorChangePluginFactoryWithOptions {
    typealias Options = EarlyEndContentPluginOptions
    let dataProvider: MediaSessionDataProvider
    let options: Options
    let notifier: MediaSessionEventsNotifier

    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin {
        EarlyEndContentMediaSessionPlugin(dataProvider: dataProvider, events: events, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, options: Options) {
        self.dataProvider = dataProvider
        self.options = options
        self.notifier = events
        super.init(events: events.asObservables,
                   timer: options.timer)
    }

    private func contentEnded() {
        bag.dispose()
        notifier.onPlaybackStateChange.publish(.ended) // TODO: maybe we do need a state change plugin otherwise this won't change an actual state change (?)
    }

    override public func pingHandler() {
        guard let playhead = dataProvider.delegate?.getPlayhead(),
              let duration = dataProvider.mediaMetadata.duration else { return }
        let percentage = calculatePercentage(playhead: playhead,
                                             duration: duration)
        if percentage >= options.percentageToComplete {
            contentEnded()
        }
    }

    public override func onSuspend(for state: MediaSessionState.PlaybackState) {
        if state != .ended {
            pingHandler()
        }
    }
}

public class EndContentMediaSessionPlugin: MediaSessionPlugin, TrackingPluginFactoryWithOptions {
    public typealias Options = EndContentPluginOptions
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        EndContentMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }
    let bag = TealiumDisposeBag()
    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        
        events.onPlaybackStateChange.subscribe { [weak self] state in
            if state == .ended {
                self?.bag.dispose()
                tracker.requestTrack(.event(.contentEnd))
            }
        }
    }
}
