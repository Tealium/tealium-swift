//
//  TealiumLoggerConstants.swift
//  TealiumLogger
//
//  Created by Craig Rouse on 23/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumLoggerKey {
    static let moduleName = "logger"
    static let shouldEnable = "com.tealium.logger.enable"
}

enum TealiumLoggerModuleError: Error {
    case moduleDisabled
    case noAccount
    case noProfile
    case noEnvironment
}
