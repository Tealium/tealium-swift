//
//  TealiumModule.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumModule {
    var id: String { get }
    var config: TealiumConfig { get set }
}
