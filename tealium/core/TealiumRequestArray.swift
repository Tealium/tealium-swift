//
//  TealiumQueue.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/25/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

extension Array where Element: TealiumRequest {

    /// Have the array loop through each element, executing the given code block
    ///     for each loop.
    ///
    /// - Parameter executing: Closure to run for each iteration.
    mutating func emptyFIFO(executing: (_ request: TealiumRequest) -> Void) {

        for request in self {

            executing(request)

        }

        self.removeAll()

    }

}
