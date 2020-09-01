//
//  TealiumLoggerProtocol.swift
//  TestHost
//
//  Created by Craig Rouse on 28/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumLoggerProtocol {
    var config: TealiumConfig? { get set }
    init(config: TealiumConfig)
    func log(_ request: TealiumLogRequest)
}
