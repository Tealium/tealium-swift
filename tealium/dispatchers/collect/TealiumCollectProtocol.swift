//
//  CollectProtocol.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public protocol CollectProtocol {

    /// Dispatches data to an HTTP endpoint, then calls optional completion block when finished￼.
    ///
    /// - Parameters:
    ///     - data: `[String:Any]` of variables to be dispatched￼
    ///     - completion: `ModuleCompletion?` Optional completion block to be called when operation complete
    func dispatch(data: [String: Any],
                  completion: ModuleCompletion?)

    /// Dispatches batched data to an HTTP endpoint, then calls optional completion block when finished￼.
    ///
    /// - Parameters:
    ///     - data: `[String:Any]` of variables to be dispatched￼
    ///     - completion: `ModuleCompletion?` Optional completion block to be called when operation complete
    func dispatchBulk(data: [String: Any],
                      completion: ModuleCompletion?)
}
