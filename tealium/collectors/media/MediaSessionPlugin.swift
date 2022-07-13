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

public extension MediaSessionPlugin {
    /// Calculates the duration of the content, in seconds
    static func calculateDuration(since: Date?) -> Double? {
        guard let since = since else {
            return nil
        }
        let calculated = Calendar.current.dateComponents([.second],
                                                         from: since,
                                                         to: Date())
        return Double(calculated.second ?? 0)
    }
}

public protocol BehaviorChangePluginFactory {
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier) -> MediaSessionPlugin
}

public protocol BehaviorChangePluginFactoryWithOptions {
    associatedtype Options
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin
}

public protocol TrackingPluginFactory { // tracking
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin
}

public protocol TrackingPluginFactoryWithOptions { // tracking
    associatedtype Options
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin
}

public struct AnyPluginFactory {

    private let createBlock: (MediaSessionDataProvider, MediaSessionEventsNotifier, MediaTracker) -> (MediaSessionPlugin)

    public init<P: TrackingPluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { dataProvider, events, tracker in
            return plugin.create(dataProvider: dataProvider,
                                 events: events.asObservables,
                                 tracker: tracker,
                                 options: options)
        }
    }

    public init<P: TrackingPluginFactory>(_ plugin: P.Type) {
        createBlock = { dataProvider, events, tracker in
            return plugin.create(dataProvider: dataProvider,
                                 events: events.asObservables,
                                 tracker: tracker)
        }
    }

    public init<P: BehaviorChangePluginFactory>(_ plugin: P.Type) {
        createBlock = { dataProvider, events, _ in
            return plugin.create(dataProvider: dataProvider,
                                 events: events)
        }
    }

    public init<P: BehaviorChangePluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { dataProvider, events, _ in
            return plugin.create(dataProvider: dataProvider,
                                 events: events,
                                 options: options)
        }
    }

    func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, tracker: MediaTracker) -> MediaSessionPlugin {
        createBlock(dataProvider, events, tracker)
    }
}

public class MediaSession2 {
    private let notifier: MediaSessionEventsNotifier
    private let dataProvider: MediaSessionDataProvider
    private let plugins: [MediaSessionPlugin]
    init(dataProvider: MediaSessionDataProvider, pluginFactory: [AnyPluginFactory], moduleDelegate: ModuleDelegate?) {
        let notifier = MediaSessionEventsNotifier()
        self.notifier = notifier
        self.dataProvider = dataProvider
        let tracker = Tracker(dataProvider: dataProvider,
                              delegate: moduleDelegate)
        plugins = pluginFactory.map { $0.create(dataProvider: dataProvider,
                                                events: notifier,
                                                tracker: tracker)
        }
    }

    class Tracker: MediaTracker {
        weak var delegate: ModuleDelegate?
        let dataProvider: MediaSessionDataProvider
        init(dataProvider: MediaSessionDataProvider, delegate: ModuleDelegate?) {
            self.dataProvider = dataProvider
            self.delegate = delegate
        }
        func requestTrack(_ event: MediaEvent, dataLayer: [String: Any]?) {
            var data = dataLayer ?? [:]
            data += dataProvider.trackingData
            delegate?.requestTrack(TealiumEvent(event.toString,
                                                dataLayer: data).trackRequest)
        }
    }

    public func play() {
        dataProvider.state.playback = .playing
    }
    public func pause() {
        dataProvider.state.playback = .paused
    }
    public func startSession() {
        notifier.onStartSession.publish()
    }
    public func loadedMetadata(metadata: MediaMetadata) {
        let merged = dataProvider.state.mediaMetadata.merging(metadata: metadata)
        dataProvider.state.mediaMetadata = merged
    }
    public func resumeSession() {
        notifier.onResumeSession.publish()
    }
    public func startChapter(_ chapter: Chapter) {
        notifier.onStartChapter.publish(chapter)
        dataProvider.state.chapters.append(chapter)
    }
    public func skipChapter() {
        notifier.onSkipChapter.publish()
    }
    public func endChapter() {
        notifier.onEndChapter.publish()
    }
    public func startBuffer() {
        notifier.onStartBuffer.publish()
        dataProvider.state.buffering = true
    }
    public func endBuffer() {
        notifier.onEndBuffer.publish()
        dataProvider.state.buffering = false
    }
    public func startSeek(at position: Double?) {
        notifier.onStartSeek.publish(position)
    }
    public func endSeek(at position: Double?) {
        notifier.onEndSeek.publish(position)
    }
    public func changePlayerPosition(_ position: MediaSessionState.PlayerPosition) {
        dataProvider.state.position = position
    }
    public func relevantQoEChange() {
        notifier.onRelevantQoEChange.publish()
    }
    public func mute(_ muted: Bool) {
        dataProvider.state.muted = muted
    }
    public func closedCaption(_ closedCaptionOn: Bool) {
        dataProvider.state.closedCaption = closedCaptionOn
    }
    public func startAdBreak(_ adBreak: AdBreak) {
        notifier.onStartAdBreak.publish(adBreak)
        dataProvider.state.adBreaks.append(adBreak)
    }
    public func endAdBreak() {
        notifier.onEndAdBreak.publish()
    }
    public func startAd(_ adv: Ad) {
        notifier.onStartAd.publish(adv)
        dataProvider.state.ads.append(adv)
        dataProvider.state.adPlaying = true
    }
    public func adStartBuffer() {
        notifier.onStartBufferAd.publish()
        dataProvider.state.adBuffering = true
    }
    public func adEndBuffer() {
        notifier.onEndBufferAd.publish()
        dataProvider.state.adBuffering = false
    }
    public func clickAd() {
        notifier.onClickAd.publish()
    }
    public func skipAd() {
        notifier.onSkipAd.publish()
        dataProvider.state.adPlaying = false
    }
    public func endAd() {
        notifier.onEndAd.publish()
        dataProvider.state.adPlaying = false
    }
    public func custom(_ event: String, dataLayer: [String: Any]? = nil) {
        notifier.onCustomEvent.publish((event, dataLayer))
    }
    public func endContent() {
        dataProvider.state.playback = .ended
    }
    public func endSession() {
        notifier.onEndSession.publish()
    }

    public func addCustomData(_ dataLayer: [String: Any]) {
        dataProvider.dataLayer += dataLayer
    }
    public func removeCustomData(forKey key: String) {
        dataProvider.dataLayer.removeValue(forKey: key)
    }
}

public protocol MediaSessionDelegate: AnyObject {
    func getQoE() -> QoE?
    func getPlayhead() -> Double?
}

extension MediaSessionDelegate {
    var trackingData: [String: Any] {
        var data = getQoE()?.encoded ?? [:]
        data["playhead"] = getPlayhead()
        return data
    }
}

class MediaModule2 {
    // with some sort of MediaMetadata
    class func createSession(mediaMetadata: MediaMetadata, pluginFactory: [AnyPluginFactory], delegate: MediaSessionDelegate? = nil) -> MediaSession2 {
        MediaSession2(dataProvider: MediaSessionDataProvider(mediaMetadata: mediaMetadata,
                                                             delegate: delegate),
                      pluginFactory: pluginFactory,
                      moduleDelegate: nil)
    }
}

public class MediaSessionState: NSObject, Encodable {
    @objc dynamic public var mediaMetadata: MediaMetadata
    @objc dynamic public var position: PlayerPosition = .inline
    @objc dynamic public var playback: PlaybackState = .idle
    @objc dynamic public var closedCaption: Bool = false
    @objc dynamic public var muted: Bool = false
    @objc dynamic public var buffering: Bool = false
    @objc dynamic public var adPlaying: Bool = false
    @objc dynamic public var adBuffering: Bool = false
    public var adBreaks = [AdBreak]()
    public var ads = [Ad]()
    public var chapters = [Chapter]()

    init(mediaMetadata: MediaMetadata) {
        self.mediaMetadata = mediaMetadata
    }

    @objc
    public enum PlayerPosition: Int, Encodable {
        case inline
        case pictureInPicture
        case fullscreen

        var toString: String {
            switch self {
            case .inline:
                return "inline"
            case .pictureInPicture:
                return "pictureInPicture"
            case .fullscreen:
                return "fullscreen"
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.toString)
        }
    }

    @objc
    public enum PlaybackState: Int, Encodable {
        case idle
        case playing
        case paused
        case ended

        var toString: String {
            switch self {
            case .idle:
                return "idle"
            case .playing:
                return "playing"
            case .paused:
                return "paused"
            case .ended:
                return "ended"
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.toString)
        }
    }

    enum CodingKeys: String, CodingKey {
        case position = "media_position"
        case playback = "media_playback"
        case closedCaption = "media_closedCaption"
        case muted = "media_muted"
        case buffering = "media_buffering"
        case adPlaying = "media_adPlaying"
        case adBuffering = "media_adBuffering"
        case adBreaks = "media_adBreaks"
        case ads = "media_ads"
        case chapters = "media_chapters"
    }

    func observeNew<Value>(_ keyPath: KeyPath<MediaSessionState, Value>, changeHandler: @escaping (Value) -> Void) -> NSKeyValueObservation {
        observe(keyPath, options: .new) { _, change in
            guard let value = change.newValue else { return }
            changeHandler(value)
        }
    }

    func observeOldNew<Value>(_ keyPath: KeyPath<MediaSessionState, Value>, changeHandler: @escaping (Value, Value) -> Void) -> NSKeyValueObservation {
        observe(keyPath, options: [.old, .new]) { _, change in
            guard let old = change.oldValue,
                let new = change.newValue else { return }
            changeHandler(old, new)
        }
    }
}

/// In memory dataProvider for this media session. Possibly edited by every plugin. Used when tracking data.
public class MediaSessionDataProvider {
    let uuid = UUID().uuidString
    public var dataLayer: [String: Any] = [:] // By the plugins
    public var state: MediaSessionState // By the session // TODO: need to find a way to make this only changeable from the session and not from the plugin
    weak public private(set) var delegate: MediaSessionDelegate?

    init(mediaMetadata: MediaMetadata, delegate: MediaSessionDelegate?) {
        self.state = MediaSessionState(mediaMetadata: mediaMetadata)
        self.delegate = delegate
    }

    var trackingData: [String: Any] {
        var data = dataLayer
        data["media_uuid"] = uuid
        data += delegate?.trackingData ?? [:]
        data += state.encoded?.flattened ?? [:]
        return data // merge the three things together
    }
}

// Variables are constant to make it clear that they can't really change it afterwards
public class MediaMetadata: NSObject, Codable {
    let id: String?
    let name: String?
    let duration: Int?
    let streamType: StreamType?
    let mediaType: MediaType?
    let startTime: Date?
    let playerName: String?
    let channelName: String?

    enum CodingKeys: String, CodingKey {
        case id = "media_custom_id"
        case name = "media_name"
        case streamType = "media_stream_type"
        case mediaType = "media_type"
        case startTime = "media_session_start_time"
        case duration = "media_duration"
        case playerName = "media_player_name"
        case channelName = "media_channel_name"
    }

    public init(id: String? = nil, name: String? = nil, duration: Int? = nil, streamType: StreamType? = nil,
                mediaType: MediaType? = nil, startTime: Date? = nil, playerName: String? = nil, channelName: String? = nil) {
        self.id = id
        self.name = name
        self.duration = duration
        self.streamType = streamType
        self.mediaType = mediaType
        self.startTime = startTime
        self.playerName = playerName
        self.channelName = channelName
    }

    // This is an internal method that we can use when they send us the updated metadata at the loadedMetadata event
    func merging(metadata: MediaMetadata) -> MediaMetadata {
        MediaMetadata(id: metadata.id ?? id,
                      name: metadata.name ?? name,
                      duration: metadata.duration ?? duration,
                      streamType: metadata.streamType ?? streamType,
                      mediaType: metadata.mediaType ?? mediaType,
                      startTime: metadata.startTime ?? startTime,
                      playerName: metadata.playerName ?? playerName,
                      channelName: metadata.channelName ?? channelName)
    }
}

public class MediaSessionEventsNotifier {
    public let onStartSession = TealiumPublishSubject<Void>()
    public let onResumeSession = TealiumPublishSubject<Void>()
    public let onStartChapter = TealiumPublishSubject<Chapter>()
    public let onSkipChapter = TealiumPublishSubject<Void>()
    public let onEndChapter = TealiumPublishSubject<Void>()
    public let onStartBuffer = TealiumPublishSubject<Void>()
    public let onEndBuffer = TealiumPublishSubject<Void>()
    public let onStartSeek = TealiumPublishSubject<Double?>()
    public let onEndSeek = TealiumPublishSubject<Double?>()
    public let onRelevantQoEChange = TealiumPublishSubject<Void>()
    public let onStartAdBreak = TealiumPublishSubject<AdBreak>()
    public let onEndAdBreak = TealiumPublishSubject<Void>()
    public let onStartAd = TealiumPublishSubject<Ad>()
    public let onStartBufferAd = TealiumPublishSubject<Void>()
    public let onEndBufferAd = TealiumPublishSubject<Void>()
    public let onClickAd = TealiumPublishSubject<Void>()
    public let onSkipAd = TealiumPublishSubject<Void>()
    public let onEndAd = TealiumPublishSubject<Void>()
    public let onEndSession = TealiumPublishSubject<Void>()
    public let onCustomEvent = TealiumPublishSubject<(String, [String: Any]?)>()

    var asObservables: MediaSessionEvents2 {
        MediaSessionEvents2(notifier: self)
    }
}

public class MediaSessionEvents2 {
    public let onStartSession: TealiumObservable<Void>
    public let onResumeSession: TealiumObservable<Void>
    public let onStartChapter: TealiumObservable<Chapter>
    public let onSkipChapter: TealiumObservable<Void>
    public let onEndChapter: TealiumObservable<Void>
    public let onStartBuffer: TealiumObservable<Void>
    public let onEndBuffer: TealiumObservable<Void>
    public let onStartSeek: TealiumObservable<Double?>
    public let onEndSeek: TealiumObservable<Double?>
    public let onRelevantQoEChange: TealiumObservable<Void>
    public let onStartAdBreak: TealiumObservable<AdBreak>
    public let onStartBufferAd: TealiumObservable<Void>
    public let onEndBufferAd: TealiumObservable<Void>
    public let onEndAdBreak: TealiumObservable<Void>
    public let onStartAd: TealiumObservable<Ad>
    public let onClickAd: TealiumObservable<Void>
    public let onSkipAd: TealiumObservable<Void>
    public let onEndAd: TealiumObservable<Void>
    public let onEndSession: TealiumObservable<Void>
    public let onCustomEvent: TealiumObservable<(String, [String: Any]?)>

    init(notifier: MediaSessionEventsNotifier) {
        self.onStartSession = notifier.onStartSession.asObservable()
        self.onResumeSession = notifier.onResumeSession.asObservable()
        self.onStartChapter = notifier.onStartChapter.asObservable()
        self.onSkipChapter = notifier.onSkipChapter.asObservable()
        self.onEndChapter = notifier.onEndChapter.asObservable()
        self.onStartBuffer = notifier.onStartBuffer.asObservable()
        self.onEndBuffer = notifier.onEndBuffer.asObservable()
        self.onStartSeek = notifier.onStartSeek.asObservable()
        self.onEndSeek = notifier.onEndSeek.asObservable()
        self.onRelevantQoEChange = notifier.onRelevantQoEChange.asObservable()
        self.onStartAdBreak = notifier.onStartAdBreak.asObservable()
        self.onStartBufferAd = notifier.onStartBufferAd.asObservable()
        self.onEndBufferAd = notifier.onEndBufferAd.asObservable()
        self.onEndAdBreak = notifier.onEndAdBreak.asObservable()
        self.onStartAd = notifier.onStartAd.asObservable()
        self.onClickAd = notifier.onClickAd.asObservable()
        self.onSkipAd = notifier.onSkipAd.asObservable()
        self.onEndAd = notifier.onEndAd.asObservable()
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
