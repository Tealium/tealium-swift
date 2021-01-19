//
//  MediaSessionFactory.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

public struct MediaSessionFactory {
    static func create(from media: MediaCollection,
                       with delegate: ModuleDelegate?) -> MediaSession {
        let mediaService = MediaEventService(media: media, delegate: delegate)
        switch media.trackingType {
        case .significant:
            return SignificantEventMediaSession(with: mediaService)
        case .heartbeat:
            return HeartbeatMediaSession(with: mediaService)
        case .milestone:
            return MilestoneMediaSession(with: mediaService)
        case .summary:
            return SummaryMediaSession(with: mediaService)
        }
    }
}
