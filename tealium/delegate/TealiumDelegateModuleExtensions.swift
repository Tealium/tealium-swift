//
//  TealiumDelegateModuleExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if delegate
import TealiumCore
#endif

public extension Tealium {
    func delegates() -> TealiumDelegates? {
        guard let module = modulesManager.getModule(forName: TealiumDelegateKey.moduleName) as? TealiumDelegateModule else {
            return nil
        }

        return module.delegates
    }

}

public extension TealiumConfig {

    var delegates: TealiumDelegates {
        get {
            optionalData[TealiumDelegateKey.multicastDelegates] as? TealiumDelegates ?? TealiumDelegates()
        }
        set {
            optionalData[TealiumDelegateKey.multicastDelegates] = newValue
        }
    }

    func addDelegate(_ delegate: TealiumDelegate) {
        let delegates = self.delegates
        delegates.add(delegate: delegate)
        self.delegates = delegates
    }

}

// Convenience += and -= operators for adding/removing delegates
public func += <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.add(delegate: right)
}

public func -= <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.remove(delegate: right)
}
