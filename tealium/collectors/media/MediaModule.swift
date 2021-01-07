//
//  MediaModule.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
// #if media
import TealiumCore
// #endif

public class MediaModule: Collector {
    
    public var id: String = "media"
    public var config: TealiumConfig
    weak var delegate: ModuleDelegate?
    
    public var data: [String : Any]?
    
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
    }
    
    public func track(media request: TealiumMediaTrackRequest) {
        let trackRequest = TealiumTrackRequest(data: request.data)
        delegate?.requestTrack(trackRequest)
    }
    
}

public struct TealiumMediaTrackRequest: TealiumRequest {
    
    public var typeId: String = TealiumMediaTrackRequest.instanceTypeId()
    public var data: [String: Any]

    public init(data: [String: Any]) {
        self.data = data
    }
    
    public static func instanceTypeId() -> String {
        return "media_track_request"
    }
    
}

