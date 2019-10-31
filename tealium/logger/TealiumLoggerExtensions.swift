//
//  TealiumLoggerExtensions.swift
//  TealiumLogger
//
//  Created by Craig Rouse on 23/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if logger
import TealiumCore
#endif

public extension Tealium {

    func logger() -> TealiumLogger? {
        guard let module = modulesManager.getModule(forName: TealiumLoggerKey.moduleName) as? TealiumLoggerModule else {
            return nil
        }

        return module.logger
    }
}
