//
//  MockLocationModuleDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class MockLocationModuleDelegate: ModuleDelegate {

    var trackRequest: TealiumTrackRequest?
    let didRequestTrack: (TealiumTrackRequest) -> Void
    init(didRequestTrack: @escaping (TealiumTrackRequest) -> Void) {
        self.didRequestTrack = didRequestTrack
    }

    func requestTrack(_ track: TealiumTrackRequest) {
        trackRequest = track
        didRequestTrack(track)
    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
