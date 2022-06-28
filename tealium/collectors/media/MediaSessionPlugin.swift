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

public protocol MediaSessionPlugin {
    // let order: Int // or whatever we want to ask to the plugins from the mediaSession
}

public protocol BasicPluginFactory {
    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin
}

//  protocol ReadyOptions {
//
//    func onReady(callback: () -> ())
//  }

public protocol PluginFactoryWithOptions {
    associatedtype Options//: ReadyOptions
    static func create(storage: MediaSessionStorage, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin
}

public struct AnyPluginFactory {

    private let createBlock: (MediaSessionStorage, MediaSessionEvents2, MediaTracker) -> (MediaSessionPlugin)

    public init<P: PluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { storage, events, tracker in
            return plugin.create(storage: storage, events: events, tracker: tracker, options: options)
        }
    }

    public init<P: BasicPluginFactory>(_ plugin: P.Type) {
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
    init(mediaContent: MediaContent2, pluginFactory: [AnyPluginFactory], delegate: ModuleDelegate?) {
        let events = notifier.asObservables
        let storage = MediaSessionStorage(mediaContent: mediaContent)
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
        func requestTrack(_ event: MediaEvent, dataLayer: [String: Any]?) {
            var data = dataLayer ?? [:]
            data += storage.trackingData
            delegate?.requestTrack(TealiumEvent(event.toString,
                                                dataLayer: data).trackRequest)
        }
    }

    public func play() {
        notifier.onPlay.publish()
    }
    public func pause() {
        notifier.onPause.publish()
    }
    public func startSession() {
        notifier.onStart.publish()
    }
    public func resumeSession() {
        notifier.onResume.publish()
    }
    public func startChapter(_ chapter: Chapter) {
        notifier.onStartChapter.publish(chapter)
    }
    public func skipChapter() {
        notifier.onSkipChapter.publish()
    }
    public func endChapter() {
        notifier.onEndChapter.publish()
    }
    public func startBuffer() {
        notifier.onStartBuffer.publish()
    }
    public func endBuffer() {
        notifier.onEndBuffer.publish()
    }
    public func startSeek(at position: Double?) {
        notifier.onStartSeek.publish(position)
    }
    public func endSeek(at position: Double?) {
        notifier.onEndSeek.publish(position)
    }
    public func startAdBreak(_ adBreak: AdBreak) {
        notifier.onStartAdBreak.publish(adBreak)
    }
    public func endAdBreak() {
        notifier.onEndAdBreak.publish()
    }
    public func startAd(_ adv: Ad) {
        notifier.onStartAd.publish(adv)
    }
    public func clickAd() {
        notifier.onClickAd.publish()
    }
    public func skipAd() {
        notifier.onSkipAd.publish()
    }
    public func endAd() {
        notifier.onEndAd.publish()
    }
    public func custom(_ event: String) {
        notifier.onCustomEvent.publish(event)
    }
    public func endContent() {
        notifier.onEndContent.publish()
    }
    public func endSession() {
        notifier.onEndSession.publish()
    }
}

class MediaModule2 {
    // with some sort of MediaMetadata
    class func createSession(mediaContent: MediaContent2, pluginFactory: [AnyPluginFactory]) -> MediaSession2 {
        MediaSession2(mediaContent: mediaContent, pluginFactory: pluginFactory, delegate: nil)
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
            tracker.requestTrack(.event(.play))
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
    return MediaModule2.createSession(mediaContent: MediaContent2(title: "Some title"),
                                      pluginFactory: [
                                        AnyPluginFactory(SomePluginWithOptions.self, 2),
                                        AnyPluginFactory(SomeSimplePlugin.self),
                                        AnyPluginFactory(SomePluginWithComplexOptions.self, ComplexPluginOptions(aaa: "a", bbb: 2)),
                                        AnyPluginFactory(SummaryMediaSessionPlugin.self)
                                      ])
}

/// In memory storage for this media session. Possibly edited by every plugin. Used when tracking data.
public class MediaSessionStorage {
    public let mediaContent: MediaContent2 // by the outside
    public var dataLayer: [String: Any] = [:] // By the plugins
//    let state: Any // By the session

    init(mediaContent: MediaContent2) {
        self.mediaContent = mediaContent
    }

    var trackingData: [String: Any] {
        return dataLayer // merge the three things together
    }
}

public struct MediaContent2 {
    let title: String
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
    let onCustomEvent = TealiumPublishSubject<String>()

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
    public let onCustomEvent: TealiumObservable<String>
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
        self.onCustomEvent = notifier.onCustomEvent.asObservable()
    }
}

public protocol MediaTracker {
    func requestTrack(_ event: MediaEvent, dataLayer: [String: Any]?)
}

public extension MediaTracker {
    func requestTrack(_ event: MediaEvent) {
        self.requestTrack(event, dataLayer: nil)
    }
}
