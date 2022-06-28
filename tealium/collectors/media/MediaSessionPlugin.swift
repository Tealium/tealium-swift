//
//  MediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 28/06/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

protocol MediaSessionPlugin {
    // let order: Int // or whatever we want to ask to the plugins from the mediaSession
}

protocol BasicPluginFactory {
    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin
}

//  protocol ReadyOptions {
//
//    func onReady(callback: () -> ())
//  }

protocol PluginFactoryWithOptions {
    associatedtype Options//: ReadyOptions
    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin
}

struct AnyPluginFactory {

    private let createBlock: (MediaSessionStorage, MediaSessionEvents2, MediaTracker) -> (MediaSessionPlugin)

    init<P: PluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { storage, events, tracker in
            return plugin.create(storage: storage, events: events, tracker: tracker, options: options)
        }
    }

    init<P: BasicPluginFactory>(_ plugin: P.Type) {
        createBlock = plugin.create
    }

    func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        createBlock(storage, events, tracker)
    }
}

public class MediaSession2 {
    private let notifier = MediaSessionEventsNotifier()
    private let storage: MediaSessionStorage
    private let plugins: [MediaSessionPlugin]
    init(pluginFactory: [AnyPluginFactory], delegate: ModuleDelegate?) {
        let events = notifier.asObservables
        let storage = MediaSessionStorage()
        self.storage = storage
        let tracker = Tracker(storage: storage, delegate: delegate)
        plugins = pluginFactory.map { $0.create(storage: storage,
                                                events: events,
                                                tracker: tracker)
        }
    }

    class Tracker: MediaTracker {
        weak var delegate: ModuleDelegate?
        let storage: MediaSessionStorage
        init(storage: MediaSessionStorage, delegate: ModuleDelegate?) {
            self.storage = storage
            self.delegate = delegate
        }
        func requestTrack(_ track: TealiumTrackRequest) {
            delegate?.requestTrack(track)
        }
    }

    public func play() {
        notifier.onPlay.publish()
    }

    public func pause() {
        notifier.onPause.publish()
    }
}

class MediaModule2 {
    // with some sort of MediaMetadata
    class func createSession(pluginFactory: [AnyPluginFactory]) -> MediaSession2 {
        MediaSession2(pluginFactory: pluginFactory, delegate: nil)
    }
}

class SomePluginWithOptions: PluginFactoryWithOptions, MediaSessionPlugin {
    typealias Options = Int

    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        return SomePluginWithOptions(storage: storage, events: events, tracker: tracker, options: options)
    }

    init(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        print(options)

        events.onPlay.subscribe { _ in
            tracker.requestTrack(TealiumEvent(StandardMediaEvent.play.rawValue).trackRequest)
        }
    }
}

struct ComplexPluginOptions {
    let aaa: String
    let bbb: Int
}

class SomePluginWithComplexOptions: PluginFactoryWithOptions, MediaSessionPlugin {
    typealias Options = ComplexPluginOptions

    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        return SomePluginWithComplexOptions(storage: storage, events: events, tracker: tracker, options: options)
    }
    init(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        print(options)
    }
}

class SomeSimplePlugin: BasicPluginFactory, MediaSessionPlugin {
    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SomeSimplePlugin(storage: storage, events: events, tracker: tracker)
    }

    init(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker) {

    }
}

func usage() -> MediaSession2 {
    // Pass the MediaMetadata too
    return MediaModule2.createSession(pluginFactory: [
        AnyPluginFactory(SomePluginWithOptions.self, 2),
        AnyPluginFactory(SomeSimplePlugin.self),
        AnyPluginFactory(SomePluginWithComplexOptions.self, ComplexPluginOptions(aaa: "a", bbb: 2)),
        AnyPluginFactory(SummaryMediaSessionPlugin.self)
    ])
}

/// In memory storage for this media session. Possibly edited by every plugin. Used when tracking data.
class MediaSessionStorage {
//    let mediaContent: MediaContent // by the outside
    var dataLayer: [String: Any] = [:] // By the plugins
//    let state: Any // By the session
//
//    var trackingData: [String: Any] {
//
//        return [:] // merge the three things together
//    }
}

class MediaSessionEventsNotifier {
    let onStart = TealiumPublishSubject<Void>()
    let onResume = TealiumPublishSubject<Void>()
    let onPlay = TealiumPublishSubject<Void>()
    let onPause = TealiumPublishSubject<Void>()
    let onStartChapter = TealiumPublishSubject<Chapter>()
    let onSkipChapter = TealiumPublishSubject<Void>()
    let onEndChapter = TealiumPublishSubject<Void>()
    let onStartBuffer = TealiumPublishSubject<Void>()
    let onEndBuffer = TealiumPublishSubject<Void>()
    let onStartSeek = TealiumPublishSubject<Double?>()
    let onEndSeek = TealiumPublishSubject<Double?>()
    let onStartAdBreak = TealiumPublishSubject<AdBreak>()
    let onEndAdBreak = TealiumPublishSubject<Void>()
    let onStartAd = TealiumPublishSubject<Ad>()
    let onClickAd = TealiumPublishSubject<Void>()
    let onSkipAd = TealiumPublishSubject<Void>()
    let onEndAd = TealiumPublishSubject<Void>()
    let onEndContent = TealiumPublishSubject<Void>()
    let onEndSession = TealiumPublishSubject<Void>()

    var asObservables: MediaSessionEvents2 {
        MediaSessionEvents2(notifier: self)
    }
}

public class MediaSessionEvents2 {
    public let onStart: TealiumObservable<Void>
    public let onResume: TealiumObservable<Void>
    public let onPlay: TealiumObservable<Void>
    public let onPause: TealiumObservable<Void>
    public let onStartChapter: TealiumObservable<Chapter>
    public let onSkipChapter: TealiumObservable<Void>
    public let onEndChapter: TealiumObservable<Void>
    public let onStartBuffer: TealiumObservable<Void>
    public let onEndBuffer: TealiumObservable<Void>
    public let onStartSeek: TealiumObservable<Double?>
    public let onEndSeek: TealiumObservable<Double?>
    public let onStartAdBreak: TealiumObservable<AdBreak>
    public let onEndAdBreak: TealiumObservable<Void>
    public let onStartAd: TealiumObservable<Ad>
    public let onClickAd: TealiumObservable<Void>
    public let onSkipAd: TealiumObservable<Void>
    public let onEndAd: TealiumObservable<Void>
    public let onEndContent: TealiumObservable<Void>
    public let onEndSession: TealiumObservable<Void>
//    func custom(_ event: String)
//    func sendMilestone(_ milestone: Milestone)
//    func ping()
//    func stopPing()
//    func setSummaryInfo()

    init(notifier: MediaSessionEventsNotifier) {
        self.onStart = notifier.onStart.asObservable()
        self.onResume = notifier.onResume.asObservable()
        self.onPlay = notifier.onPlay.asObservable()
        self.onPause = notifier.onPause.asObservable()
        self.onStartChapter = notifier.onStartChapter.asObservable()
        self.onSkipChapter = notifier.onSkipChapter.asObservable()
        self.onEndChapter = notifier.onEndChapter.asObservable()
        self.onStartBuffer = notifier.onStartBuffer.asObservable()
        self.onEndBuffer = notifier.onEndBuffer.asObservable()
        self.onStartSeek = notifier.onStartSeek.asObservable()
        self.onEndSeek = notifier.onEndSeek.asObservable()
        self.onStartAdBreak = notifier.onStartAdBreak.asObservable()
        self.onEndAdBreak = notifier.onEndAdBreak.asObservable()
        self.onStartAd = notifier.onStartAd.asObservable()
        self.onClickAd = notifier.onClickAd.asObservable()
        self.onSkipAd = notifier.onSkipAd.asObservable()
        self.onEndAd = notifier.onEndAd.asObservable()
        self.onEndContent = notifier.onEndContent.asObservable()
        self.onEndSession = notifier.onEndSession.asObservable()
    }
}

protocol MediaTracker {
    func requestTrack(_ track: TealiumTrackRequest)
}

class MediaTrackerImpl: MediaTracker {
    func requestTrack(_ track: TealiumTrackRequest) {
        print(track)
    }
}
