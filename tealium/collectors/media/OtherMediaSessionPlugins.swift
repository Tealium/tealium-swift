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

public class CustomEventMediaTrackingPlugin: MediaSessionPlugin, TrackingPluginFactory {
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        CustomEventMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    let bag = TealiumDisposeBag()

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        events.onCustomEvent.subscribe { event, dataLayer in
            tracker.requestTrack(.custom(event), dataLayer: dataLayer)
        }.toDisposeBag(bag)
    }
}

public class LoadedMetadataMediaTrackingPlugin: MediaSessionPlugin, TrackingPluginFactory {
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        LoadedMetadataMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    let bag = TealiumDisposeBag()

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        dataProvider.state.observeNew(\.mediaMetadata) { metadata in
            tracker.requestTrack(.event(.loadedMetadata), dataLayer: metadata.encoded)
        }.toDisposeBag(bag)
    }
}

public class EndContentMediaTrackingPlugin: MediaSessionPlugin, TrackingPluginFactory {
    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        EndContentMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }
    let bag = TealiumDisposeBag()
    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        dataProvider.state.observeNew(\.playback) { [weak self] state in
            if state == .ended {
                self?.bag.dispose()
                tracker.requestTrack(.event(.contentEnd))
            }
        }.toDisposeBag(bag)
    }
}
