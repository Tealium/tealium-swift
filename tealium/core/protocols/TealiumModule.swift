//
//  ModuleProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumModule {
    var id: String { get }
    var config: TealiumConfig { get set }
}
