//
//  MediaDispatch.swift
//  tealium-swift
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

public protocol MediaDispatch: TealiumDispatch {
    var event: MediaEvent { get }
    var parameters: TealiumMedia { get }
    var segment: Segment? { get }
}

public struct TealiumMediaEvent: MediaDispatch {
    public var event: MediaEvent
    public var parameters: TealiumMedia
    public var segment: Segment?
    
    var data: [String: Any] {
        var dictionary = [String: Any]()
        switch event {
            case .event(let name): dictionary[TealiumKey.event] = name.rawValue
            case .custom(let name): dictionary[TealiumKey.event] = name
        }
        if let parameters = parameters.dictionary?.flattened {
            dictionary += parameters.flattened
        }
        if let segment = segment,
           let flattened = segment.dictionary?.flattened {
            dictionary.merge(flattened) { _, new in new }
        }
        return dictionary
    }
    
    public var trackRequest: TealiumTrackRequest {
        TealiumTrackRequest(data: self.data)
    }
    
}

