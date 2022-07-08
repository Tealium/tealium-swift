//
//  OtherMediaSessionPlugins.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class CustomTrackerMediaSessionPlugin: MediaSessionPlugin, BasicPluginFactory {
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        CustomTrackerMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    let bag = TealiumDisposeBag()

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        events.onCustomEvent.subscribe { event, dataLayer in
            tracker.requestTrack(.custom(event), dataLayer: dataLayer)
        }.toDisposeBag(bag)
    }
}

public class LoadedMetadataTrackerMediaSessionPlugin: MediaSessionPlugin, BasicPluginFactory {
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        LoadedMetadataTrackerMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    let bag = TealiumDisposeBag()

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        events.onLoadedMetadata.subscribe { metadata in
            tracker.requestTrack(.event(.loadedMetadata), dataLayer: metadata.encoded)
        }.toDisposeBag(bag)
    }
}
