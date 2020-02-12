//
//  TealiumModulesList.swift
//  TealiumCore
//
//  Created by Craig Rouse on 17/01/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// White or black list of module names to enable. TealiumConfig can be set
///     with this list which will be read by internal components to determine
///     which modules to spin up, if they are included with the existing build.
public struct TealiumModulesList: Equatable {
    public let isWhitelist: Bool
    public let moduleNames: Set<String>
    var filtered: Set<String> {
        let moduleNames: Set<String> = Set(TealiumModuleNames.allCases.map {
            $0.rawValue
        })
        return moduleNames.filter {
            if self.isWhitelist == false {
                return !self.moduleNames.contains($0)
            } else {
                return self.moduleNames.contains($0)
            }
        }
    }

    enum TealiumModuleNames: String, CaseIterable {
        case autotracking
        case appdata
        case attribution
        case collect
        case connectivity
        case consentmanager
        case crash
        case delegate
        case devicedata
        case dispatchqueue
        case lifecycle
        case location
        case logger
        case persistentdata
        case remotecommands
        case tagmanagement
        case visitorservice
        case volatiledata
    }

    public init(isWhitelist: Bool,
                moduleNames: Set<String>) {
        self.isWhitelist = isWhitelist
        self.moduleNames = Set(moduleNames.map {
            $0.lowercased()
        })
    }
}
