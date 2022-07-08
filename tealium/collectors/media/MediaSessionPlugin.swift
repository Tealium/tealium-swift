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

public protocol BasicPluginFactory {
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin
}

//  protocol ReadyOptions {
//
//    func onReady(callback: () -> ())
//  }

public protocol PluginFactoryWithOptions {
    associatedtype Options//: ReadyOptions
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin
}

public struct AnyPluginFactory {

    private let createBlock: (MediaSessionDataProvider, MediaSessionEvents2, MediaTracker) -> (MediaSessionPlugin)

    public init<P: PluginFactoryWithOptions, Options>(_ plugin: P.Type, _ options: Options) where P.Options == Options {
        createBlock = { dataProvider, events, tracker in
            return plugin.create(dataProvider: dataProvider,
                                 events: events,
                                 tracker: tracker,
                                 options: options)
        }
    }

    public init<P: BasicPluginFactory>(_ plugin: P.Type) {
        createBlock = plugin.create
    }

    func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        createBlock(dataProvider, events, tracker)
    }
}

public class MediaSession2 {
    private let notifier = MediaSessionEventsNotifier()
    private let dataProvider: MediaSessionDataProvider
    private let plugins: [MediaSessionPlugin]
    init(dataProvider: MediaSessionDataProvider, pluginFactory: [AnyPluginFactory], moduleDelegate: ModuleDelegate?) {
        let events = notifier.asObservables
        self.dataProvider = dataProvider
        let tracker = Tracker(dataProvider: dataProvider,
                              delegate: moduleDelegate)
        plugins = pluginFactory.map { $0.create(dataProvider: dataProvider,
                                                events: events,
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
        notifier.onPlaybackStateChange.publish(.playing)
        dataProvider.state.playback = .playing
    }
    public func pause() {
        notifier.onPlaybackStateChange.publish(.paused)
        dataProvider.state.playback = .paused
    }
    public func startSession() {
        notifier.onStart.publish()
    }
    public func loadedMetadata(metadata: MediaMetadata) {
        let merged = dataProvider.mediaMetadata.merging(metadata: metadata)
        notifier.onLoadedMetadata.publish(merged)
        dataProvider.mediaMetadata = merged
    }
    public func resumeSession() {
        notifier.onResume.publish()
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
        notifier.onPlayerPosition.publish(position)
        dataProvider.state.position = position
    }
    public func relevantQoEChange() {
        notifier.onRelevantQoEChange.publish()
    }
    public func mute(_ muted: Bool) {
        notifier.onMuted.publish(muted)
        dataProvider.state.muted = muted
    }
    public func closedCaption(_ closedCaptionOn: Bool) {
        notifier.onClosedCaption.publish(closedCaptionOn)
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
    public func custom(_ event: String) {
        notifier.onCustomEvent.publish(event)
    }
    public func endContent() {
        notifier.onPlaybackStateChange.publish(.ended)
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

class SomePluginWithOptions: PluginFactoryWithOptions, MediaSessionPlugin {
    typealias Options = Int

    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        SomePluginWithOptions(dataProvider: dataProvider,
                              events: events,
                              tracker: tracker,
                              options: options)
    }

    init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        print(options)

        events.onPlaybackStateChange.subscribe { state in
            if state == .playing {
                tracker.requestTrack(.event(.play))
            }
        }
    }
}

struct ComplexPluginOptions {
    let aaa: String
    let bbb: Int
}

class SomePluginWithComplexOptions: PluginFactoryWithOptions, MediaSessionPlugin {
    typealias Options = ComplexPluginOptions

    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) -> MediaSessionPlugin {
        SomePluginWithComplexOptions(dataProvider: dataProvider,
                                     events: events,
                                     tracker: tracker,
                                     options: options)
    }
    init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker, options: Options) {
        print(options)
    }
}

class SomeSimplePlugin: BasicPluginFactory, MediaSessionPlugin {
    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SomeSimplePlugin(dataProvider: dataProvider,
                         events: events,
                         tracker: tracker)
    }

    init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {

    }
}

func usage() -> MediaSession2 {
    // Pass the MediaMetadata too
    return MediaModule2.createSession(mediaMetadata: MediaMetadata(id: "12345", name: "Some title"),
                                      pluginFactory: [
                                        AnyPluginFactory(SomePluginWithOptions.self, 2),
                                        AnyPluginFactory(SomeSimplePlugin.self),
                                        AnyPluginFactory(SomePluginWithComplexOptions.self, ComplexPluginOptions(aaa: "a", bbb: 2)),
                                        AnyPluginFactory(SummaryMediaSessionPlugin.self)
                                      ])
}

public struct MediaSessionState: Codable {
    var position: PlayerPosition = .inline
    var playback: PlaybackState = .idle
    var closedCaption: Bool = false
    var muted: Bool = false
    var buffering: Bool = false
    var adPlaying: Bool = false
    var adBuffering: Bool = false
    var adBreaks = [AdBreak]()
    var ads = [Ad]()
    var chapters = [Chapter]()

    public enum PlayerPosition: String, Codable {
        case inline
        case pictureInPicture
        case fullscreen
    }

    public enum PlaybackState: String, Codable {
        case idle
        case playing
        case paused
        case ended
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
}

/// In memory dataProvider for this media session. Possibly edited by every plugin. Used when tracking data.
public class MediaSessionDataProvider {
    let uuid = UUID().uuidString
    public var mediaMetadata: MediaMetadata // by the outside
    public var dataLayer: [String: Any] = [:] // By the plugins
    public var state = MediaSessionState() // By the session
    weak public private(set) var delegate: MediaSessionDelegate?

    init(mediaMetadata: MediaMetadata, delegate: MediaSessionDelegate?) {
        self.mediaMetadata = mediaMetadata
        self.delegate = delegate
    }

    var trackingData: [String: Any] {
        var data = dataLayer
        data["media_uuid"] = uuid
        data += mediaMetadata.encoded ?? [:]
        data += delegate?.trackingData ?? [:]
        data += state.encoded ?? [:]
        return data // merge the three things together
    }
}

// Variables are constant to make it clear that they can't really change it afterwards
public struct MediaMetadata: Codable {
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

class MediaSessionEventsNotifier {
    let onStart = TealiumPublishSubject<Void>()
    let onLoadedMetadata = TealiumPublishSubject<MediaMetadata>()
    let onResume = TealiumPublishSubject<Void>()
    let onPlaybackStateChange = TealiumPublishSubject<MediaSessionState.PlaybackState>()
    let onStartChapter = TealiumPublishSubject<Chapter>()
    let onSkipChapter = TealiumPublishSubject<Void>()
    let onEndChapter = TealiumPublishSubject<Void>()
    let onStartBuffer = TealiumPublishSubject<Void>()
    let onEndBuffer = TealiumPublishSubject<Void>()
    let onStartSeek = TealiumPublishSubject<Double?>()
    let onEndSeek = TealiumPublishSubject<Double?>()
    let onPlayerPosition = TealiumPublishSubject<MediaSessionState.PlayerPosition>()
    let onMuted = TealiumPublishSubject<Bool>()
    let onClosedCaption = TealiumPublishSubject<Bool>()
    let onRelevantQoEChange = TealiumPublishSubject<Void>()
    let onStartAdBreak = TealiumPublishSubject<AdBreak>()
    let onEndAdBreak = TealiumPublishSubject<Void>()
    let onStartAd = TealiumPublishSubject<Ad>()
    let onStartBufferAd = TealiumPublishSubject<Void>()
    let onEndBufferAd = TealiumPublishSubject<Void>()
    let onClickAd = TealiumPublishSubject<Void>()
    let onSkipAd = TealiumPublishSubject<Void>()
    let onEndAd = TealiumPublishSubject<Void>()
    let onEndSession = TealiumPublishSubject<Void>()
    let onCustomEvent = TealiumPublishSubject<String>()

    var asObservables: MediaSessionEvents2 {
        MediaSessionEvents2(notifier: self)
    }
}

public class MediaSessionEvents2 {
    public let onStart: TealiumObservable<Void>
    public let onLoadedMetadata: TealiumObservable<MediaMetadata>
    public let onResume: TealiumObservable<Void>
    public let onPlaybackStateChange: TealiumObservable<MediaSessionState.PlaybackState>
    public let onStartChapter: TealiumObservable<Chapter>
    public let onSkipChapter: TealiumObservable<Void>
    public let onEndChapter: TealiumObservable<Void>
    public let onStartBuffer: TealiumObservable<Void>
    public let onEndBuffer: TealiumObservable<Void>
    public let onStartSeek: TealiumObservable<Double?>
    public let onEndSeek: TealiumObservable<Double?>
    public let onPlayerPosition: TealiumObservable<MediaSessionState.PlayerPosition>
    public let onRelevantQoEChange: TealiumObservable<Void>
    public let onMuted: TealiumObservable<Bool>
    public let onClosedCaption: TealiumObservable<Bool>
    public let onStartAdBreak: TealiumObservable<AdBreak>
    public let onStartBufferAd: TealiumObservable<Void>
    public let onEndBufferAd: TealiumObservable<Void>
    public let onEndAdBreak: TealiumObservable<Void>
    public let onStartAd: TealiumObservable<Ad>
    public let onClickAd: TealiumObservable<Void>
    public let onSkipAd: TealiumObservable<Void>
    public let onEndAd: TealiumObservable<Void>
    public let onEndSession: TealiumObservable<Void>
    public let onCustomEvent: TealiumObservable<String>

    init(notifier: MediaSessionEventsNotifier) {
        self.onStart = notifier.onStart.asObservable()
        self.onLoadedMetadata = notifier.onLoadedMetadata.asObservable()
        self.onResume = notifier.onResume.asObservable()
        self.onPlaybackStateChange = notifier.onPlaybackStateChange.asObservable()
        self.onStartChapter = notifier.onStartChapter.asObservable()
        self.onSkipChapter = notifier.onSkipChapter.asObservable()
        self.onEndChapter = notifier.onEndChapter.asObservable()
        self.onStartBuffer = notifier.onStartBuffer.asObservable()
        self.onEndBuffer = notifier.onEndBuffer.asObservable()
        self.onStartSeek = notifier.onStartSeek.asObservable()
        self.onEndSeek = notifier.onEndSeek.asObservable()
        self.onPlayerPosition = notifier.onPlayerPosition.asObservable()
        self.onRelevantQoEChange = notifier.onRelevantQoEChange.asObservable()
        self.onMuted = notifier.onMuted.asObservable()
        self.onClosedCaption = notifier.onClosedCaption.asObservable()
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
