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

    func delegates() -> TealiumDelegates {
        if let delegates = self.optionalData[TealiumDelegateKey.multicastDelegates] as? TealiumDelegates {
            return delegates
        }

        return TealiumDelegates()
    }

    func addDelegate(_ delegate: TealiumDelegate) {
        let delegates = self.delegates()
        delegates.add(delegate: delegate)
        optionalData[TealiumDelegateKey.multicastDelegates] = delegates
    }

}

// Convenience += and -= operators for adding/removing delegates
public func += <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.add(delegate: right)
}

public func -= <T: TealiumDelegate> (left: TealiumDelegates, right: T) {
    left.remove(delegate: right)
}
