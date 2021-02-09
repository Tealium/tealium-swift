//
//  Video.swift
//  iOSTealiumMediaTest
//
//  Created by Christina S on 1/19/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import AVKit

struct Video {
    var play: Bool = true
    var time: CMTime = .zero
    var autoReplay: Bool = true
    var mute: Bool = false
    var stateText: String = ""
    var totalDuration: Double = 0
    var started: Bool = false
    var paused: Bool = false
    var isBackgrounded: Bool = false
}
