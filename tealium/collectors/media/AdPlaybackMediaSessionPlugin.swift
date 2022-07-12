//
//  AdPlaybackMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class AdPlaybackMediaSessionPlugin: MediaSessionPlugin, TrackingPluginFactory {
    private var bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        AdPlaybackMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        return [
            events.onStartBufferAd.subscribe {
                tracker.requestTrack(.event(.adBufferStart))
            },
            events.onEndBufferAd.subscribe {
                tracker.requestTrack(.event(.adBufferEnd))
            },
            events.onStartAdBreak.subscribe { adBreak in
                tracker.requestTrack(.event(.adBreakStart), dataLayer: adBreak.encoded)
            },
            events.onEndAdBreak.subscribe {
                guard var adBreak = dataProvider.state.adBreaks.last else {
                    return
                }
                if adBreak.duration == nil {
                    adBreak.duration = PlaybackMediaSessionPlugin.calculateDuration(since: adBreak.startTime)
                }
                tracker.requestTrack(.event(.adBreakEnd), dataLayer: adBreak.encoded)
            },
            events.onStartAd.subscribe { adv in
                tracker.requestTrack(.event(.adStart), dataLayer: adv.encoded)
            },
            events.onEndAd.subscribe {
                guard var adv = dataProvider.state.ads.last else {
                    return
                }
                if adv.duration == nil {
                    adv.duration = PlaybackMediaSessionPlugin.calculateDuration(since: adv.startTime)
                }
                tracker.requestTrack(.event(.adEnd), dataLayer: adv.encoded)
            },
            events.onSkipAd.subscribe {
                tracker.requestTrack(.event(.adSkip), dataLayer: dataProvider.state.ads.last?.encoded)
            },
            events.onClickAd.subscribe {
                tracker.requestTrack(.event(.adClick), dataLayer: dataProvider.state.ads.last?.encoded)
            }
        ]
    }
}
