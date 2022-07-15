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
                tracker.requestTrack(.event(.adBreakStart), segment: .adBreak(adBreak))
            },
            events.onEndAdBreak.subscribe {
                guard var adBreak = dataProvider.state.adBreaks.last else {
                    return
                }
                if adBreak.duration == nil {
                    adBreak.duration = PlaybackMediaTrackingPlugin.calculateDuration(since: adBreak.startTime)
                }
                tracker.requestTrack(.event(.adBreakEnd), segment: .adBreak(adBreak))
            },
            events.onStartAd.subscribe { adv in
                tracker.requestTrack(.event(.adStart), segment: .ad(adv))
            },
            events.onEndAd.subscribe {
                guard var adv = dataProvider.state.ads.last else {
                    return
                }
                if adv.duration == nil {
                    adv.duration = PlaybackMediaTrackingPlugin.calculateDuration(since: adv.startTime)
                }
                tracker.requestTrack(.event(.adEnd), segment: .ad(adv))
            },
            events.onSkipAd.subscribe {
                guard let adv = dataProvider.state.ads.last else { return }
                tracker.requestTrack(.event(.adSkip), segment: .ad(adv))
            },
            events.onClickAd.subscribe {
                guard let adv = dataProvider.state.ads.last else { return }
                tracker.requestTrack(.event(.adClick), segment: .ad(adv))
            }
        ]
    }
}
