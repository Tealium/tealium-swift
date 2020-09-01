//
//  Array+Tealium.swift
//  TealiumCore
//
//  Created by Jonathan Wong on 8/25/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Array {
    // Credit: https://gist.github.com/ericdke/fa262bdece59ff786fcb#gistcomment-2045033
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
