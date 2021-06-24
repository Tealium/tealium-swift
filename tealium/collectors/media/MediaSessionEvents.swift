//
//  MediaSessionEvents.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol MediaSessionEvents {
    func startSession()
    func resumeSession()
    func play()
    func startChapter(_ chapter: Chapter)
    func skipChapter()
    func endChapter()
    func startBuffer()
    func endBuffer()
    func startSeek(at position: Double?)
    func endSeek(at position: Double?)
    func startAdBreak(_ adBreak: AdBreak)
    func endAdBreak()
    func startAd(_ ad: Ad)
    func clickAd()
    func skipAd()
    func endAd()
    func pause()
    func custom(_ event: String)
    func sendMilestone(_ milestone: Milestone)
    func ping()
    func stopPing()
    func setSummaryInfo()
    func endContent()
    func endSession()
}
