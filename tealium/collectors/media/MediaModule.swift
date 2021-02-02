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
    
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
        self.delegate = delegate
    }
    
    /// Creates a `MediaSession` for a given tracking type
    /// - Parameter media: `MediaCollection` containing meta information
    /// - Returns: `MediaSession` type
    public func createSession(from media: MediaContent) -> MediaSession {
        MediaSessionFactory.create(from: media, with: delegate)
    }
    
}


