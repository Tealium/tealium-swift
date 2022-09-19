//
//  MediaDispatch.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public protocol MediaDispatch: TealiumDispatch {
    var event: MediaEvent { get }
    var parameters: MediaContent { get }
    var segment: Segment? { get }
}

public struct TealiumMediaEvent: MediaDispatch {
    public var event: MediaEvent
    public var parameters: MediaContent
    public var segment: Segment?

    /// Consolidates all the data from the media session for a given track call
    /// - Returns; `[String: Any]`, flattened
    var data: [String: Any] {
        trackRequest.trackDictionary
    }

    public var trackRequest: TealiumTrackRequest {
        let eventName: String
        switch event {
        case .event(let name):
            if name.rawValue != StandardMediaEvent.milestone.rawValue {
                parameters.milestone = nil
            }
            eventName = name.rawValue
        case .custom(let name):
            eventName = name
        }
        var dictionary = [String: Any]()
        if let parameters = parameters.encoded?.flattened {
            dictionary += parameters.flattened
        }
        if let segment = segment,
           let flattened = segment.dictionary?.flattened {
            dictionary.merge(flattened) { _, new in new }
        }
        return TealiumEvent(eventName, dataLayer: dictionary).trackRequest
    }

}
