//
//  MediaSessionEvents.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol MediaSessionEvents {
    func startSession()
    func play()
    func startChapter(_ chapter: Chapter)
    func skipChapter()
    func endChapter()
    func startBuffer()
    func endBuffer()
    func startSeek(at position: Int?)
    func endSeek(at position: Int?)
    func startAdBreak(_ adBreak: AdBreak)
    func endAdBreak()
    func startAd(_ ad: Ad)
    func clickAd()
    func skipAd()
    func endAd()
    func pause()
    func stop()
    func custom(_ event: String)
    func sendMilestone(_ milestone: Milestone)
    func ping()
    func stopPing()
    func setSummaryInfo()
    func endSession()
}
