//
//  MediaSessionEvents.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol MediaSessionEvents {
    func completeAdBreak()
    func startAdBreak(_ adBreak: AdBreak)
    func clickAd()
    func completeAd()
    func skipAd()
    func startAd(_ ad: Ad)
    func completeBuffer()
    func startBuffer()
    func completeChapter()
    func skipChapter()
    func startChapter(_ chapter: Chapter)
    func endSession()
    func custom(_ event: String)
    func pause()
    func play()
    func startSeek()
    func completeSeek()
    func startSession()
    func stop()
}
