//
//  TealiumRemoteCommandsErrors.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandsModuleError: LocalizedError {
    case wasDisabled

    public var errorDescription: String? {
        switch self {
        case .wasDisabled:
            return NSLocalizedString("Module disabled by config setting.", comment: "RemoteCommandModuleDisabled")
        }
    }
}

public enum TealiumRemoteCommandsError: Error {
    case invalidScheme
    case noCommandIdFound
    case noCommandForCommandIdFound
    case remoteCommandsDisabled
    case requestNotProperlyFormatted
}
