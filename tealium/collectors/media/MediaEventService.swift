//
//  MediaEventService.swift
//  TealiumMedia
//
//  Created by Christina S on 1/13/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

public protocol MediaEventDispatcher {
    var delegate: ModuleDelegate? { get set }
    var media: TealiumMedia { get set }
    func track(_ event: MediaEvent)
    func track(_ event: MediaEvent,
               _ segment: Segment?)
}

public extension MediaEventDispatcher {
    
    func track(_ event: MediaEvent) {
        track(event, nil)
    }
    
    func track(_ event: MediaEvent,
                      _ segment: Segment?) {
        let mediaEvent = TealiumMediaEvent(event: event,
                                           parameters: media,
                                           segment: segment)
        delegate?.requestTrack(mediaEvent.trackRequest)
    }
}

public struct MediaEventService: MediaEventDispatcher {
    public var media: TealiumMedia
    public var delegate: ModuleDelegate?
}
