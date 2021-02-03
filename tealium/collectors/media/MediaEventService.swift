//
//  MediaEventService.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public protocol MediaEventDispatcher {
    var delegate: ModuleDelegate? { get set }
    var media: MediaContent { get set }
    func track(_ event: MediaEvent)
    func track(_ event: MediaEvent,
               _ segment: Segment?)
}

public extension MediaEventDispatcher {
    
    func track(_ event: MediaEvent) {
        track(event, nil)
    }
    
    /// Calls the `ModuleDelegate.requestTrack(_:)` with the provided media information
    /// - Parameters:
    ///   - event: current `MediaEvent`
    ///   - segment: provided if event is one that requires a `Segment` type
    func track(_ event: MediaEvent,
                      _ segment: Segment?) {
        let mediaEvent = TealiumMediaEvent(event: event,
                                           parameters: media,
                                           segment: segment)
        delegate?.requestTrack(mediaEvent.trackRequest)
    }
}

public struct MediaEventService: MediaEventDispatcher {
    public var media: MediaContent
    public var delegate: ModuleDelegate?
}
