//
//  BlocklistProvider.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//
import Foundation
#if autotracking
import TealiumCore
#endif

class BlocklistProvider: ItemsProvider<String> {
    private static func location(from config: TealiumConfig) -> ItemsFileLocation {
        if let file = config.autoTrackingBlocklistFilename {
            return .local(file)
        } else if let url = config.autoTrackingBlocklistURL {
            return .remote(url)
        } else {
            return .none
        }
    }
    init(config: TealiumConfig,
         bundle: Bundle,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         diskStorage: TealiumDiskStorageProtocol) {
        super.init(id: "blocklist",
                   location: Self.location(from: config),
                   bundle: bundle,
                   urlSession: urlSession,
                   diskStorage: diskStorage,
                   logger: config.logger)
    }
}
