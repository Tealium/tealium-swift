//
//  MediaSession.swift
//  TealiumCore
//
//  Created by Christina S on 1/6/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

public protocol MediaSessionProtocol: MediaSessionEvents {
    var bitrate: Int? { get set }
    var droppedFrames: Int { get set }
    var mediaService: MediaEventDispatcher? { get set }
    var playbackSpeed: Double { get set }
    var playerState: PlayerState? { get set }
}

public class MediaSession: MediaSessionProtocol {
    
    public var mediaService: MediaEventDispatcher?
    
    public init(with mediaService: MediaEventDispatcher?) {
        self.mediaService = mediaService
    }
    
    public var bitrate: Int? {
        get { mediaService?.media.qoe.bitrate }
        set {
            if let newValue = newValue {
                mediaService?.media.qoe.bitrate = newValue
                mediaService?.track(.event(.bitrateChange))
            }
        }
    }
    
    public var droppedFrames: Int {
        get { mediaService?.media.qoe.droppedFrames ?? 0 }
        set {
            mediaService?.media.qoe.droppedFrames = newValue
        }
    }
    
    public var playbackSpeed: Double {
        get { mediaService?.media.qoe.playbackSpeed ?? 1.0 }
        set {
            mediaService?.media.qoe.playbackSpeed = newValue
        }
    }
    
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
    
    public func adBreakComplete() {
        guard var adBreak = mediaService?.media.adBreaks.first else {
            return
        }
        if adBreak.duration == nil {
            adBreak.duration = calculate(duration: adBreak.startTime)
        }
        mediaService?.track(
            .event(.adBreakComplete),
            .adBreak(adBreak)
        )
        mediaService?.media.remove(by: adBreak.uuid)
    }
    
    public func adBreakStart(_ adBreak: AdBreak) {
        mediaService?.media.add(.adBreak(adBreak))
        mediaService?.track(
            .event(.adBreakStart),
            .adBreak(adBreak)
        )
    }
    
    public func adClick() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adClick),
            .ad(ad)
        )
        mediaService?.media.remove(by: ad.uuid)
    }
    
    public func adComplete() {
        guard var ad = mediaService?.media.ads.first else {
            return
        }
        if ad.duration == nil {
            ad.duration = calculate(duration: ad.startTime)
        }
        mediaService?.track(
            .event(.adComplete),
            .ad(ad)
        )
        mediaService?.media.remove(by: ad.uuid)
    }
    
    public func adSkip() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adSkip),
            .ad(ad)
        )
        mediaService?.media.remove(by: ad.uuid)
    }
    
    public func adStart(_ ad: Ad) {
        mediaService?.media.add(.ad(ad))
        mediaService?.track(
            .event(.adStart),
            .ad(ad)
        )
    }
    
    public func bufferComplete() {
        mediaService?.track(.event(.bufferComplete))
    }
    
    public func bufferStart() {
        mediaService?.track(.event(.bufferStart))
    }
    
    public func chapterComplete() {
        guard let chapter = mediaService?.media.chapters.last else {
            return
        }
        mediaService?.track(
            .event(.chapterComplete),
            .chapter(chapter)
        )
        mediaService?.media.remove(by: chapter.uuid)
    }
    
    public func chapterSkip() {
        guard let chapter = mediaService?.media.chapters.last else {
            return
        }
        mediaService?.track(
            .event(.chapterSkip),
            .chapter(chapter)
        )
        mediaService?.media.remove(by: chapter.uuid)
    }
    
    public func chapterStart(_ chapter: Chapter) {
        mediaService?.media.add(.chapter(chapter))
        mediaService?.track(
            .event(.chapterStart),
            .chapter(chapter)
        )
    }
    
    public func close() {
        mediaService?.track(.event(.sessionEnd))
    }
    
    public func custom(_ event: String) {
        mediaService?.track(.custom(event))
    }
    
    public func seek() {
        mediaService?.track(.event(.seekStart))
    }
    
    public func seekComplete() {
        mediaService?.track(.event(.seekComplete))
    }
    
    public func start() {
        mediaService?.track(.event(.sessionStart))
    }
    
    public func play() {
        mediaService?.track(.event(.play))
    }
    
    public func pause() {
        mediaService?.track(.event(.pause))
    }
    
    public func stop() {
        mediaService?.track(.event(.stop))
    }
    
    private func calculate(duration: Date) -> Int? {
        let duration = Calendar.current.dateComponents([.second],
                                                       from: duration,
                                                       to: Date())
        return duration.second
    }
    
}

