//
//  MediaSessionEvents.swift
//  TealiumMedia
//
//  Created by Christina S on 1/12/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol MediaSessionEvents {
    mutating func adBreakComplete()
    mutating func adBreakStart(_ adBreak: AdBreak)
    mutating func adClick()
    mutating func adComplete()
    mutating func adSkip()
    mutating func adStart(_ ad: Ad)
    func bufferComplete()
    func bufferStart()
    mutating func chapterComplete()
    mutating func chapterSkip()
    mutating func chapterStart(_ chapter: Chapter)
    func close()
    func custom(_ event: String)
    func pause()
    func play()
    func seek()
    func seekComplete()
    func start()
    func stop()
}
