//
//  ItemsFileLocation+Blocklist.swift
//  TealiumLocation
//
//  Created by Enrico Zannini on 25/02/25.
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
