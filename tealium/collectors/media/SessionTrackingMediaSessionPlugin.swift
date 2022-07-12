//
//  SessionTrackingMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public struct SessionTrackingMediaPluginOptions {
    public struct AutotrackingBackgroundSessions {

    }

    let timer: Repeater

    public init(interval: Double) {
        self.init(timer: TealiumRepeatingTimer(timeInterval: interval,
                                               dispatchQueue: TealiumQueues.backgroundSerialQueue))
    }

    init(timer: Repeater) {
        self.timer = timer
    }
}

public class SessionTrackingMediaSessionPlugin: MediaSessionPlugin, TrackingPluginFactoryWithOptions {
    public typealias Options = SessionTrackingMediaPluginOptions
    let bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        SessionTrackingMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker, options: options)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        [
            events.onStartSession.subscribe {
                // TODO: implement
            },
            events.onResumeSession.subscribe {
                // TODO: implement
            },
            events.onEndSession.subscribe {
                // TODO: implement
            }
        ]
    }
}

class BackgroundBehaviorSessionPlugin {

}
