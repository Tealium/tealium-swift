//
//  TealiumDelegateConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumDelegateKey {
    static let moduleName = "delegate"
    static let multicastDelegates = "com.tealium.delegate.delegates"
}

public enum TealiumDelegateError: Error {
    case suppressedByShouldTrackDelegate
}
