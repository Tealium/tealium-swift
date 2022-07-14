//
//  SessionMediaTrackingPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class SessionMediaTrackingPlugin: MediaSessionPlugin, TrackingPluginFactory {
    let bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SessionMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        [
            events.onStartSession.subscribe {
                tracker.requestTrack(.event(.sessionStart))
            },
            events.onResumeSession.subscribe {
                tracker.requestTrack(.event(.sessionResume))
            },
            events.onEndSession.subscribe {
                tracker.requestTrack(.event(.sessionEnd))
            }
        ]
    }
}
