//
//  ModuleDelegate.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ModuleDelegate: class {

    /// Called by a module send a new track request to the Dispatch Manager
    ///
    /// - Parameter track: TealiumTrackRequest
    func requestTrack(_ track: TealiumTrackRequest)

    /// Called by a module requesting to dequeue all queued requests
    /// - Parameter reason: `String` containing the reason for the dequeue request
    func requestDequeue(reason: String)

    /// Called by the Remote Commands module when requesting Remote Command execution
    /// - Parameter reason: `String` containing the reason for the dequeue request
    func processRemoteCommandRequest(_ request: TealiumRequest)
}
