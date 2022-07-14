//
//  PlaybackMediaTrackingPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class PlaybackMediaTrackingPlugin: MediaSessionPlugin, TrackingPluginFactory {
    private var bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        PlaybackMediaTrackingPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        return [
            dataProvider.state.observeNew(\.playback) { state in
                switch state {
                case .playing:
                    tracker.requestTrack(.event(.play))
                case .paused:
                    tracker.requestTrack(.event(.pause))
                default:
                    break
                }
            },
            events.onStartSeek.subscribe { _ in
                tracker.requestTrack(.event(.seekStart))
            },
            events.onEndSeek.subscribe { _ in
                tracker.requestTrack(.event(.seekEnd))
            },
            events.onStartBuffer.subscribe {
                tracker.requestTrack(.event(.bufferStart))
            },
            events.onEndBuffer.subscribe {
                tracker.requestTrack(.event(.bufferEnd))
            },
            events.onStartChapter.subscribe { chapter in
                tracker.requestTrack(.event(.chapterStart), dataLayer: chapter.encoded)
            },
            events.onSkipChapter.subscribe {
                tracker.requestTrack(.event(.chapterSkip), dataLayer: dataProvider.state.chapters.last?.encoded)
            },
            events.onEndChapter.subscribe {
                guard var chapter = dataProvider.state.chapters.last else {
                    return
                }
                if chapter.duration == nil {
                    chapter.duration = PlaybackMediaTrackingPlugin.calculateDuration(since: chapter.startTime)
                }
                tracker.requestTrack(.event(.chapterEnd), dataLayer: chapter.encoded)
            }
        ]
    }
}
