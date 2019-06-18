//
//  TealiumCollectProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/1/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public protocol TealiumCollectProtocol {

    /// Dispatches data to an HTTP endpoint, then calls optional completion block when finished
    ///
    /// - Parameters:
    /// - data: [String:Any] of variables to be dispatched
    /// - completion: Optional completion block to be called when operation complete
    func dispatch(data: [String: Any],
                  completion: TealiumCompletion?)
}
