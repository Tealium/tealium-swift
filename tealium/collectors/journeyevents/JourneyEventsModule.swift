//
// Created by Craig Rouse on 04/02/2021.
// Copyright (c) 2021 Tealium, Inc. All rights reserved.
//

import Foundation

class JourneyEvents: Collector {
    private(set) var data: [String: Any]? = nil

    required init(context: TealiumContextProtocol, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ModuleCompletion) {
        self.config = context.config
    }

    private(set) var id: String = ""
    var config: TealiumConfig
}
