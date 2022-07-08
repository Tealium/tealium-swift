//
//  IntervalMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public struct IntervalPluginOptions {
    let timer: Repeater

    public init(interval: Double) {
        self.init(timer: TealiumRepeatingTimer(timeInterval: interval,
                                               dispatchQueue: TealiumQueues.backgroundSerialQueue))
    }

    init(timer: Repeater) {
        self.timer = timer
    }
}

public class IntervalMediaSessionPlugin: MediaSessionPingPlugin, MediaSessionPlugin, PluginFactoryWithOptions {
    public typealias Options = IntervalPluginOptions
    let dataProvider: MediaSessionDataProvider
    let tracker: MediaTracker
    let options: Options

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        IntervalMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        self.dataProvider = dataProvider
        self.options = options
        self.tracker = tracker
        super.init(events: events, timer: options.timer)
    }

    override public func pingHandler() {
        tracker.requestTrack(.event(.interval))
    }
}
