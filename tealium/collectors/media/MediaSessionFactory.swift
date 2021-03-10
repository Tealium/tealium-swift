//
//  MediaSessionFactory.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public struct MediaSessionFactory {
    static func create(from media: MediaContent,
                       with delegate: ModuleDelegate?) -> MediaSession {
        let mediaService = MediaEventService(media: media, delegate: delegate)
        switch media.trackingType {
        case .significant:
            return SignificantEventMediaSession(with: mediaService)
        case .heartbeat:
            return HeartbeatMediaSession(with: mediaService)
        case .milestone:
            return MilestoneMediaSession(with: mediaService, interval: mediaService.media.milestoneInterval ?? 5.0)
        case .heartbeatMilestone:
            return HeartbeatMilestoneMediaSession(with: mediaService, interval: 1.0)
        case .summary:
            return SummaryMediaSession(with: mediaService)
        }
    }
}
