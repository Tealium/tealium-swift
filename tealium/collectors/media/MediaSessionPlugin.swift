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
    static func create(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier) -> MediaSessionPlugin
}

public protocol BehaviorChangePluginFactoryWithOptions {
    associatedtype Options
    static func create(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin
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
        createBlock = { dataProvider, notifier, tracker in
            return plugin.create(dataProvider: dataProvider,
                                 events: notifier.asObservables,
                                 tracker: tracker,
                                 options: options)
        }
    }

    public init<P: TrackingPluginFactory>(_ plugin: P.Type) {
        createBlock = { dataProvider, notifier, tracker in
            return plugin.create(dataProvider: dataProvider,
                                 events: notifier.asObservables,
                                 tracker: tracker)
        }
    }

    public init<P: BehaviorChangePluginFactory>(_ plugin: P.Type) {
        createBlock = { dataProvider, notifier, _ in
            return plugin.create(dataProvider: dataProvider,
                                 notifier: notifier)
        }
    }

    public init<P: BehaviorChangePluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { dataProvider, notifier, _ in
            return plugin.create(dataProvider: dataProvider,
                                 notifier: notifier,
                                 options: options)
        }
    }

    func create(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, tracker: MediaTracker) -> MediaSessionPlugin {
        createBlock(dataProvider, notifier, tracker)
    }
}

public class MediaSession2 {
    private let notifier: MediaSessionEventsNotifier
    private let dataProvider: MediaSessionDataProvider
    private let plugins: [MediaSessionPlugin]
    init(dataProvider: MediaSessionDataProvider, pluginFactory: [AnyPluginFactory], moduleDelegate: ModuleDelegate?) {
        let notifier = MediaSessionEventsNotifier(stateUpdater: MediaSessionStateUpdater(state: dataProvider.state))
        self.notifier = notifier
        self.dataProvider = dataProvider
        let tracker = Tracker(dataProvider: dataProvider,
                              delegate: moduleDelegate)
        plugins = pluginFactory.map { $0.create(dataProvider: dataProvider,
                                                notifier: notifier,
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
        notifier.stateUpdater.playback = .playing
    }
    public func pause() {
        notifier.stateUpdater.playback = .paused
    }
    public func startSession() {
        notifier.onStartSession.publish()
    }
    public func loadedMetadata(metadata: MediaMetadata) {
        let merged = dataProvider.state.mediaMetadata.merging(metadata: metadata)
        notifier.stateUpdater.mediaMetadata = merged
    }
    public func resumeSession() {
        notifier.onResumeSession.publish()
    }
    public func startChapter(_ chapter: Chapter) {
        notifier.onStartChapter.publish(chapter)
        notifier.stateUpdater.chapters.append(chapter)
    }
    public func skipChapter() {
        notifier.onSkipChapter.publish()
    }
    public func endChapter() {
        notifier.onEndChapter.publish()
    }
    public func startBuffer() {
        notifier.onStartBuffer.publish()
        notifier.stateUpdater.buffering = true
    }
    public func endBuffer() {
        notifier.onEndBuffer.publish()
        notifier.stateUpdater.buffering = false
    }
    public func startSeek(at position: Double?) {
        notifier.onStartSeek.publish(position)
    }
    public func endSeek(at position: Double?) {
        notifier.onEndSeek.publish(position)
    }
    public func changePlayerPosition(_ position: MediaSessionState.PlayerPosition) {
        notifier.stateUpdater.position = position
    }
    public func relevantQoEChange() {
        notifier.onRelevantQoEChange.publish()
    }
    public func mute(_ muted: Bool) {
        notifier.stateUpdater.muted = muted
    }
    public func closedCaption(_ closedCaptionOn: Bool) {
        notifier.stateUpdater.closedCaption = closedCaptionOn
    }
    public func startAdBreak(_ adBreak: AdBreak) {
        notifier.onStartAdBreak.publish(adBreak)
        notifier.stateUpdater.adBreaks.append(adBreak)
    }
    public func endAdBreak() {
        notifier.onEndAdBreak.publish()
    }
    public func startAd(_ adv: Ad) {
        notifier.onStartAd.publish(adv)
        notifier.stateUpdater.ads.append(adv)
        notifier.stateUpdater.adPlaying = true
    }
    public func adStartBuffer() {
        notifier.onStartBufferAd.publish()
        notifier.stateUpdater.adBuffering = true
    }
    public func adEndBuffer() {
        notifier.onEndBufferAd.publish()
        notifier.stateUpdater.adBuffering = false
    }
    public func clickAd() {
        notifier.onClickAd.publish()
    }
    public func skipAd() {
        notifier.onSkipAd.publish()
        notifier.stateUpdater.adPlaying = false
    }
    public func endAd() {
        notifier.onEndAd.publish()
        notifier.stateUpdater.adPlaying = false
    }
    public func custom(_ event: String, dataLayer: [String: Any]? = nil) {
        notifier.onCustomEvent.publish((event, dataLayer))
    }
    public func endContent() {
        notifier.stateUpdater.playback = .ended
    }
    public func endSession() {
        notifier.onEndSession.publish()
    }

    public func addCustomData(_ dataLayer: [String: Any]) {
        dataProvider.dataLayer += dataLayer
    }
    public func getCustomData(forKey key: String) -> Any? {
        dataProvider.dataLayer[key]
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

/// In memory dataProvider for this media session. Possibly edited by every plugin. Used when tracking data.
public class MediaSessionDataProvider {
    let uuid = UUID().uuidString
    public var dataLayer: [String: Any] = [:] // By the plugins
    public var state: MediaSessionState // By the session

    weak public private(set) var delegate: MediaSessionDelegate?

    init(mediaMetadata: MediaMetadata, delegate: MediaSessionDelegate?) {
        self.state = MediaSessionState(mediaMetadata: mediaMetadata)
        self.delegate = delegate
    }

    var trackingData: [String: Any] {
        var data = dataLayer
        data["media_uuid"] = uuid
        data += delegate?.trackingData.flattened ?? [:]
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
    public let stateUpdater: MediaSessionStateUpdater

    init(stateUpdater: MediaSessionStateUpdater) {
        self.stateUpdater = stateUpdater
    }

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

    func requestTrack(_ event: MediaEvent, segment: Segment) {
        self.requestTrack(event, dataLayer: segment.dictionary?.flattened)
    }
}
