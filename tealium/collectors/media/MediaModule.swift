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
    
    public var id: String = "Media"
    public var config: TealiumConfig
    weak var delegate: ModuleDelegate?
    
    public var data: [String : Any]?
    
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
        self.delegate = delegate
    }
    
    public func createSession(from media: TealiumMedia) -> MediaSession {
        MediaSessionFactory.create(from: media, with: delegate)
    }
    
}

struct TealiumMediaTrackRequest: TealiumRequest, MediaRequest {
    var typeId: String = TealiumMediaTrackRequest.instanceTypeId()
    public var event: MediaEvent
    public var parameters: TealiumMedia
    
    var trackRequest: TealiumTrackRequest {
        TealiumTrackRequest(data: self.dictionary)
    }
    
    static func instanceTypeId() -> String {
        "media_track_request"
    }
    
    
}

public protocol MediaRequest {
    var event: MediaEvent { get }
    var parameters: TealiumMedia { get }
    var dictionary: [String: Any] { get }
}

extension MediaRequest {
    public var dictionary: [String : Any] {
        var result: [String: Any] = [
         "tealium_event": event.rawValue,
         "media_uuid": UUID().uuidString,
            "media_type": parameters.mediaType.rawValue,
            "stream_type": parameters.streamType.rawValue,
         "player_name": parameters.name,
            "tracking_interval": parameters.trackingType.rawValue,
         "qoe": ["bitrate": parameters.qoe.bitrate] // shoud metadata be flattened?
        ]
        
        if let customId = parameters.customId {
            result["media_custom_id"] = customId
        }
        
        if let duration = parameters.duration {
            result["media_length"] = duration
        }
        
        if let channelName = parameters.channelName {
            result["channel_name"] = channelName
        }
        
        // filter out audio/video/custom
        if let metadata = parameters.metadata {
            result["metadata"] = metadata
        }
        
        if let milestone = parameters.milestone {
            result["milestone"] = milestone
        }
        
        // flatten and add to dictionary?
        if let summary = parameters.summary {
            result["summary"] = summary
        }
        
        return result
    }
}

public enum MediaEvent: String {
    case play = "media_play"
    case pause = "media_pause"
    case stop = "media_stop"
    case heartbeat = "media_heartbeat"
    case milestone = "media_milestone"
    case summary = "media_summary"
}

public extension Collectors {
    static let Media = MediaModule.self
}


public extension Tealium {
    /// - Returns: `MediaModule` instance
    var media: MediaModule? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == MediaModule.self
        } as? MediaModule)
    }
}
