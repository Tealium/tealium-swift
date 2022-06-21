//
//  MediaSession.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
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

//protocol ReadyOptions {
//
//    func onReady(callback: () -> ())
//}

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
            tracker.track("play")
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
        AnyPluginFactory(SomePluginWithComplexOptions.self, ComplexPluginOptions(aaa: "a", bbb: 2))
    ])
}

/// In memory storage for this media session. Possibly edited by every plugin. Used when tracking data.
class MediaSessionStorage {
//    let mediaContent: MediaContent // by the outside
//    let dataLayer: [String: Any] // By the plugins
//    let state: Any // By the session
//
//    var trackingData: [String: Any] {
//
//        return [:]
//    }
}

class MediaSessionEvents2 {
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onPlay: TealiumObservable<Void>
    @ToAnyObservable<TealiumPublishSubject<Void>>(TealiumPublishSubject<Void>())
    var onPause: TealiumObservable<Void>

}

protocol MediaTracker {
    func track(_ event: String)
}

class MediaTrackerImpl: MediaTracker {
    func track(_ event: String) {

    }
}

public protocol MediaSessionProtocol: MediaSessionEvents {
    var bitrate: Int? { get set }
    var droppedFrames: Int { get set }
    var mediaService: MediaEventDispatcher? { get set }
    var playbackSpeed: Double { get set }
    var playerState: PlayerState? { get set }
    var backgroundStatusResumed: Bool { get set }
    func calculate(duration: Date?) -> Double?
}

public class MediaSession: MediaSessionProtocol {

    public var mediaService: MediaEventDispatcher?
    public var backgroundStatusResumed = false

    public init(with mediaService: MediaEventDispatcher?) {
        self.mediaService = mediaService
    }

    /// QoE bitrate
    /// Sends a `bitrateChange` event when updated
    public var bitrate: Int? {
        get { mediaService?.media.qoe.bitrate }
        set {
            if let newValue = newValue {
                mediaService?.media.qoe.bitrate = newValue
                mediaService?.track(.event(.bitrateChange))
            }
        }
    }

    /// QoE droppedFrames
    public var droppedFrames: Int {
        get { mediaService?.media.qoe.droppedFrames ?? 0 }
        set { mediaService?.media.qoe.droppedFrames = newValue }
    }

    /// QoE playbackSpeed
    public var playbackSpeed: Double {
        get { mediaService?.media.qoe.playbackSpeed ?? 1.0 }
        set { mediaService?.media.qoe.playbackSpeed = newValue }
    }

    /// QoE playerState
    /// Sends a `playerStateStart` and `playerStateEnd` event when updated
    public var playerState: PlayerState? {
        get { mediaService?.media.state }
        set {
            if mediaService?.media.state == nil {
                mediaService?.media.state = newValue
                mediaService?.track(.event(.playerStateStart))
            } else if mediaService?.media.state != newValue {
                mediaService?.track(.event(.playerStateStop))
                mediaService?.media.state = newValue
                mediaService?.track(.event(.playerStateStart))
            }
        }
    }

    public func resumeSession() {
        backgroundStatusResumed = true
        mediaService?.track(.event(.sessionResume))
    }

    public func startSession() {
        guard !backgroundStatusResumed else {
            resumeSession()
            return
        }
        mediaService?.track(.event(.sessionStart))
    }

    public func play() {
        mediaService?.track(.event(.play))
    }

    public func startChapter(_ chapter: Chapter) {
        mediaService?.media.add(.chapter(chapter))
        mediaService?.track(
            .event(.chapterStart),
            .chapter(chapter)
        )
    }

    public func skipChapter() {
        guard let chapter = mediaService?.media.chapters.last else {
            return
        }
        mediaService?.track(
            .event(.chapterSkip),
            .chapter(chapter)
        )
    }

    public func endChapter() {
        guard var chapter = mediaService?.media.chapters.last else {
            return
        }
        if chapter.duration == nil {
            chapter.duration = calculate(duration: chapter.startTime)
        }
        mediaService?.track(
            .event(.chapterEnd),
            .chapter(chapter)
        )
    }

    public func startBuffer() {
        mediaService?.track(.event(.bufferStart))
    }

    public func endBuffer() {
        mediaService?.track(.event(.bufferEnd))
    }

    public func startSeek(at position: Double? = nil) {
        mediaService?.track(.event(.seekStart))
    }

    public func endSeek(at position: Double? = nil) {
        mediaService?.track(.event(.seekEnd))
    }

    public func startAdBreak(_ adBreak: AdBreak) {
        mediaService?.media.add(.adBreak(adBreak))
        mediaService?.track(
            .event(.adBreakStart),
            .adBreak(adBreak)
        )
    }

    /// Sends `adBreakEnd` event and calculates duration of the adBreak
    public func endAdBreak() {
        guard var adBreak = mediaService?.media.adBreaks.last else {
            return
        }
        if adBreak.duration == nil {
            adBreak.duration = calculate(duration: adBreak.startTime)
        }
        mediaService?.track(
            .event(.adBreakEnd),
            .adBreak(adBreak)
        )
    }
    // swiftlint:disable identifier_name
    public func startAd(_ ad: Ad) {
        mediaService?.media.add(.ad(ad))
        mediaService?.track(
            .event(.adStart),
            .ad(ad)
        )
    }

    public func clickAd() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adClick),
            .ad(ad)
        )
    }

    public func skipAd() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adSkip),
            .ad(ad)
        )
    }

    /// Sends `adEnd` event and calculates duration of the ad
    public func endAd() {
        guard var ad = mediaService?.media.ads.last else {
            return
        }
        if ad.duration == nil {
            ad.duration = calculate(duration: ad.startTime)
        }
        mediaService?.track(
            .event(.adEnd),
            .ad(ad)
        )
    }
    // swiftlint:enable identifier_name

    /// Sends a custom media event
    public func custom(_ event: String) {
        mediaService?.track(.custom(event))
    }

    public func pause() {
        mediaService?.track(.event(.pause))
    }

    /// Sends an event signaling that the content has played until the end
    public func endContent() {
        mediaService?.track(.event(.contentEnd))
    }

    public func endSession() {
        mediaService?.track(.event(.sessionEnd))
    }

    /// Calculates the duration of the content, in seconds
    public func calculate(duration: Date?) -> Double? {
        guard let duration = duration else {
            return nil
        }
        let calculated = Calendar.current.dateComponents([.second],
                                                         from: duration,
                                                         to: Date())
        return Double(calculated.second ?? 0)
    }

    public func sendMilestone(_ milestone: Milestone) {
        fatal(from: "\(#function)")
    }

    public func ping() {
        fatal(from: "\(#function)")
    }

    public func stopPing() {
        fatal(from: "\(#function)")
    }

    public func setSummaryInfo() {
        fatal(from: "\(#function)")
    }

    private func fatal(from function: String) {
        fatalError("\(function) must be overriden in order to use")
    }
}
