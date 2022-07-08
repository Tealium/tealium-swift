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

public class SessionTrackingMediaSessionPlugin: MediaSessionPlugin, BasicPluginFactory {
    let bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SessionTrackingMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
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
