//
//  MediaSessionState.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 14/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class MediaSessionStateUpdater {
    let state: MediaSessionState
    public var mediaMetadata: MediaMetadata {
        get { state.mediaMetadata }
        set { state.mediaMetadata = newValue }
    }
    public var position: MediaSessionState.PlayerPosition {
        get { state.position }
        set { state.position = newValue }
    }
    public var playback: MediaSessionState.PlaybackState {
        get { state.playback }
        set { state.playback = newValue }
    }
    public var closedCaption: Bool {
        get { state.closedCaption }
        set { state.closedCaption = newValue }
    }
    public var muted: Bool {
        get { state.muted }
        set { state.muted = newValue }
    }
    public var buffering: Bool {
        get { state.buffering }
        set { state.buffering = newValue }
    }
    public var adPlaying: Bool {
        get { state.adPlaying }
        set { state.adPlaying = newValue }
    }
    public var adBuffering: Bool {
        get { state.adBuffering }
        set { state.adBuffering = newValue }
    }
    public var adBreaks: [AdBreak] {
        get { state.adBreaks }
        set { state.adBreaks = newValue }
    }
    public var ads: [Ad] {
        get { state.ads }
        set { state.ads = newValue }
    }
    public var chapters: [Chapter] {
        get { state.chapters }
        set { state.chapters = newValue }
    }
    init(state: MediaSessionState) {
        self.state = state
    }
}

public class MediaSessionState: NSObject, Encodable {
    @objc dynamic public fileprivate(set) var mediaMetadata: MediaMetadata
    @objc dynamic public fileprivate(set) var position: PlayerPosition = .inline
    @objc dynamic public fileprivate(set) var playback: PlaybackState = .idle
    @objc dynamic public fileprivate(set) var closedCaption: Bool = false
    @objc dynamic public fileprivate(set) var muted: Bool = false
    @objc dynamic public fileprivate(set) var buffering: Bool = false
    @objc dynamic public fileprivate(set) var adPlaying: Bool = false
    @objc dynamic public fileprivate(set) var adBuffering: Bool = false
    public fileprivate(set) var adBreaks = [AdBreak]()
    public fileprivate(set) var ads = [Ad]()
    public fileprivate(set) var chapters = [Chapter]()

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

    public func observeNew<Value>(_ keyPath: KeyPath<MediaSessionState, Value>, changeHandler: @escaping (Value) -> Void) -> NSKeyValueObservation {
        observe(keyPath, options: .new) { _, change in
            guard let value = change.newValue else { return }
            changeHandler(value)
        }
    }

    public func observeOldNew<Value>(_ keyPath: KeyPath<MediaSessionState, Value>, changeHandler: @escaping (Value, Value) -> Void) -> NSKeyValueObservation {
        observe(keyPath, options: [.old, .new]) { _, change in
            guard let old = change.oldValue,
                let new = change.newValue else { return }
            changeHandler(old, new)
        }
    }
}
