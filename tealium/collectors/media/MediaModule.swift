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
    public var data: [String : Any]?
    weak var delegate: ModuleDelegate?
    
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

public protocol MediaRequest: TealiumRequest {
    var event: MediaEvent { get }
    var parameters: TealiumMedia { get }
    var segment: Segmentable? { get }
}

struct TealiumMediaTrackRequest: MediaRequest {
    var typeId: String = TealiumMediaTrackRequest.instanceTypeId()
    public var event: MediaEvent
    public var parameters: TealiumMedia
    public var segment: Segmentable?
    
    public var data: [String: Any] {
        var dictionary = [String: Any]()
        switch event {
            case .event(let name): dictionary[TealiumKey.event] = name.rawValue
            case .custom(let name): dictionary[TealiumKey.event] = name
        }
        if let parameters = parameters.dictionary {
            dictionary += parameters
        }
        if let segmentParameters = segment?.dictionary {
            dictionary += segmentParameters
        }
        return dictionary
    }
    
    var trackRequest: TealiumTrackRequest {
        TealiumTrackRequest(data: self.data)
    }
    
    static func instanceTypeId() -> String {
        "media_track_request"
    }
    
}

public enum StandardMediaEvent: String {
    case adBreakEnd = "media_adbreak_complete"
    case adBreakStart = "media_adbreak_start"
    case adClick = "media_ad_click"
    case adComplete = "media_ad_complete"
    case adSkip = "media_ad_skip"
    case adStart = "media_ad_start"
    case bitrateChange = "media_bitrate_change" // *
    case bufferEnd = "media_buffer_end"  // *
    case bufferStart = "media_buffer_start"  // *
    case chapterComplete = "media_chapter_complete"
    case chapterSkip = "media_chapter_skip"
    case chapterStart = "media_chapter_start"
    case complete = "media_session_complete" // *
    case custom = "custom_media_event" // *
    case heartbeat = "media_heartbeat"
    case milestone = "media_milestone"
    case pause = "media_pause" // *
    case play = "media_play" // *
    case playerStateStart = "player_state_start" // *
    case playerStateStop = "player_state_stop" // *
    case seekStart = "media_seek_start"  // *
    case seekComplete = "media_seek_complete"  // *
    case start = "media_session_start" // *
    case stop = "media_stop" // *
    case summary = "media_summary"
}

public enum MediaEvent {
    case event(StandardMediaEvent)
    case custom(String)
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
