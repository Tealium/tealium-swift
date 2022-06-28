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

class Session {
    let events = MediaSessionEvents2()

    func play() {
//        events.onPlay.notify()
    }
}

class MediaModule2 {
    // with some sort of MediaMetadata
    class func createSession(pluginFactory: [AnyPluginFactory]) -> [MediaSessionPlugin] {
        pluginFactory.map { $0.create(storage: MediaSessionStorage(),
                                      events: MediaSessionEvents2(),
                                      tracker: MediaTrackerImpl())
        }
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

func usage() -> [MediaSessionPlugin] {
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

class MediaSessionEvents2 {
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onStart: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onResume: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onPlay: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onPause: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Chapter>>(TealiumPublishSubject<Chapter>())
    var onStartChapter: TealiumObservable<Chapter>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onSkipChapter: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndChapter: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onStartBuffer: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndBuffer: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Double?>>(TealiumPublishSubject<Double?>())
    var onStartSeek: TealiumObservable<Double?>
    @ToAnyObservable<TealiumPublishSubject<Double?>>(TealiumPublishSubject<Double?>())
    var onEndSeek: TealiumObservable<Double?>
    @ToAnyObservable<TealiumPublishSubject<AdBreak>>(TealiumPublishSubject<AdBreak>())
    var onStartAdBreak: TealiumObservable<AdBreak>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndAdBreak: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Ad>>(TealiumPublishSubject<Ad>())
    var onStartAd: TealiumObservable<Ad>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onClickAd: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onSkipAd: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndAd: TealiumObservable<Void>
//    func custom(_ event: String)
//    func sendMilestone(_ milestone: Milestone)
//    func ping()
//    func stopPing()
//    func setSummaryInfo()
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndContent: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onEndSession: TealiumObservable<Void>
}

protocol MediaTracker {
    func requestTrack(_ track: TealiumTrackRequest)
}

class MediaTrackerImpl: MediaTracker {
    func requestTrack(_ track: TealiumTrackRequest) {
        print(track)
    }
}
