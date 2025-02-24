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

extension ItemsFileLocation {
    init(blocklistConfiguration config: TealiumConfig) {
        if let file = config.autoTrackingBlocklistFilename {
            self = .local(file)
        } else if let url = config.autoTrackingBlocklistURL {
            self = .remote(url)
        } else {
            self = .none
        }
    }
}

class BlocklistProvider: ItemsProvider<String> {
    init(config: TealiumConfig,
         bundle: Bundle,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         diskStorage: TealiumDiskStorageProtocol) {
        super.init(id: "blocklist",
                   location: ItemsFileLocation(blocklistConfiguration: config),
                   bundle: bundle,
                   urlSession: urlSession,
                   diskStorage: diskStorage,
                   logger: config.logger)
    }
}
