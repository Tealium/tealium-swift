//
//  TealiumVisitorProfileConfigExtensions.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public extension TealiumConfig {

    func setVisitorServiceRefresh(interval: Int64) {
        optionalData[TealiumVisitorProfileConstants.refreshInterval] = interval
    }

    func addVisitorServiceDelegate(_ delegate: TealiumVisitorServiceDelegate) {
        var delegates = getVisitorServiceDelegates() ?? [TealiumVisitorServiceDelegate]()
        delegates.append(delegate)
        optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] = delegates
    }

    func getVisitorServiceDelegates() -> [TealiumVisitorServiceDelegate]? {
        return optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] as? [TealiumVisitorServiceDelegate]
    }
}
