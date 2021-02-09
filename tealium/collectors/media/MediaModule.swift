//
//  MediaModule.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public class MediaModule: Collector {
    
    public var id: String = "Media"
    public var config: TealiumConfig
    public var data: [String : Any]?
    weak var delegate: ModuleDelegate?
    var activeSessions = [MediaSession]()
    
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
        self.delegate = delegate
        Tealium.lifecycleListeners.addDelegate(delegate: self)
    }
    
    /// Creates a `MediaSession` for a given tracking type
    /// - Parameter media: `MediaCollection` containing meta information
    /// - Returns: `MediaSession` type
    public func createSession(from media: MediaContent) -> MediaSession {
        let session = MediaSessionFactory.create(from: media, with: delegate)
        activeSessions.append(session)
        return session
    }
    
}

extension MediaModule: TealiumLifecycleEvents {
    
    public func sleep() {
        guard config.enableBackgroundMediaTracking else {
            return
        }
        activeSessions.forEach { session in
            session.backgroundStatusResumed = false
            TealiumQueues.mainQueue.asyncAfter(deadline:
                                                .now() + config.backgroundMediaAutoEndSessionTime) {
                if !session.backgroundStatusResumed {
                    session.endSession()
                }
            }
        }
    }
    
    public func wake() {
        guard config.enableBackgroundMediaTracking else {
            return
        }
        activeSessions.forEach { session in
            session.backgroundStatusResumed = true
        }
    }
    
    public func launch(at date: Date) { }
}

