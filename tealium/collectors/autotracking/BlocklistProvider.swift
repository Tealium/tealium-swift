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
