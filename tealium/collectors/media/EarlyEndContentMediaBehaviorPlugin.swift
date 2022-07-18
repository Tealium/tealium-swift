//
//  EarlyEndContentMediaBehaviorPlugin.swift
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

class EarlyEndContentMediaBehaviorPlugin: MediaSessionPingPlugin, MediaSessionPlugin, BehaviorChangePluginFactoryWithOptions {
    typealias Options = EarlyEndContentPluginOptions
    let dataProvider: MediaSessionDataProvider
    let options: Options
    let notifier: MediaSessionEventsNotifier

    static func create(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin {
        EarlyEndContentMediaBehaviorPlugin(dataProvider: dataProvider, notifier: notifier, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, options: Options) {
        self.dataProvider = dataProvider
        self.options = options
        self.notifier = notifier
        super.init(dataProvider: dataProvider,
                   events: notifier.asObservables,
                   timer: options.timer)
    }

    private func contentEnded() {
        notifier.stateUpdater.playback = .ended
    }

    override public func pingHandler() {
        guard let playhead = dataProvider.delegate?.getPlayhead(),
              let duration = dataProvider.state.mediaMetadata.duration else { return }
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
