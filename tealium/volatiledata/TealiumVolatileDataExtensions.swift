//
//  TealiumVolatileDataExtensions.swift
//  TealiumVolatileData
//
//  Created by Craig Rouse on 24/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if volatiledata
import TealiumCore
#endif

public extension Tealium {

    func volatileData() -> TealiumVolatileData? {
        guard let module = modulesManager.getModule(forName: TealiumVolatileDataKey.moduleName) as? TealiumVolatileDataModule else {
            return nil
        }

        return module.volatileData
    }
}
