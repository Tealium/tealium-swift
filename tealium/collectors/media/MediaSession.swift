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

public protocol MediaSession: MediaSessionEvents {
    var bitrate: Int? { get set }
    var droppedFrames: Int { get set }
    var mediaService: MediaEventDispatcher? { get set }
    var playbackSpeed: Double { get set }
    var playerState: PlayerState? { get set }
}

public extension MediaSession {
    
    var bitrate: Int? {
        get { mediaService?.media.qoe.bitrate }
        set {
            if let newValue = newValue {
                mediaService?.media.qoe.bitrate = newValue
                mediaService?.track(.event(.bitrateChange))
            }
        }
    }
    
    var droppedFrames: Int {
        get { mediaService?.media.qoe.droppedFrames ?? 0 }
        set {
            mediaService?.media.qoe.droppedFrames = newValue
        }
    }
    
    var playbackSpeed: Double {
        get { mediaService?.media.qoe.playbackSpeed ?? 1.0 }
        set {
            mediaService?.media.qoe.playbackSpeed = newValue
        }
    }
    
    var playerState: PlayerState? {
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
    
    mutating func adBreakComplete() {
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
        mediaService?.media.adBreaks.removeFirst(1)
    }
    
    mutating func adBreakStart(_ adBreak: AdBreak) {
        mediaService?.media.adBreaks.append(adBreak)
        mediaService?.track(
            .event(.adBreakStart),
            .adBreak(adBreak)
        )
    }
    
    mutating func adClick() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adClick),
            .ad(ad)
        )
        mediaService?.media.ads.removeLast()
    }
    
    mutating func adComplete() {
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
        mediaService?.media.ads.removeFirst(1)
    }
    
    mutating func adSkip() {
        guard let ad = mediaService?.media.ads.last else {
            return
        }
        mediaService?.track(
            .event(.adSkip),
            .ad(ad)
        )
        mediaService?.media.ads.removeLast()
    }
    
    mutating func adStart(_ ad: Ad) {
        mediaService?.media.ads.append(ad)
        mediaService?.track(
            .event(.adStart),
            .ad(ad)
        )
    }
    
    func bufferComplete() {
        mediaService?.track(.event(.bufferComplete))
    }
    
    func bufferStart() {
        mediaService?.track(.event(.bufferStart))
    }
    
    mutating func chapterComplete() {
        guard let chapter = mediaService?.media.chapters.last else {
            return
        }
        mediaService?.track(
            .event(.chapterComplete),
            .chapter(chapter)
        )
        mediaService?.media.chapters.removeLast()
    }
    
    mutating func chapterSkip() {
        guard let chapter = mediaService?.media.chapters.last else {
            return
        }
        mediaService?.track(
            .event(.chapterSkip),
            .chapter(chapter)
        )
        mediaService?.media.chapters.removeLast()
    }
    
    mutating func chapterStart(_ chapter: Chapter) {
        mediaService?.media.chapters.append(chapter)
        mediaService?.track(
            .event(.chapterStart),
            .chapter(chapter)
        )
    }
    
    func close() {
        mediaService?.track(.event(.sessionEnd))
    }
    
    func custom(_ event: String) {
        mediaService?.track(.custom(event))
    }
    
    func seek() {
        mediaService?.track(.event(.seekStart))
    }
    
    func seekComplete() {
        mediaService?.track(.event(.seekComplete))
    }
    
    func start() {
        mediaService?.track(.event(.sessionStart))
    }
    
    func play() {
        mediaService?.track(.event(.play))
    }
    
    func pause() {
        mediaService?.track(.event(.pause))
    }
    
    func stop() {
        mediaService?.track(.event(.stop))
    }
    
    private func calculate(duration: Date) -> Int? {
        let duration = Calendar.current.dateComponents([.second],
                                                       from: duration,
                                                       to: Date())
        return duration.second
    }
    
}

