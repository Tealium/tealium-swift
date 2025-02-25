//
//  ItemsFileLocation+Geofence.swift
//  TealiumLocation
//
//  Created by Enrico Zannini on 25/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
#if location
import TealiumCore
#endif

extension ItemsFileLocation {
    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    private static func url(from config: TealiumConfig) -> String {
        return "\(TealiumValue.tealiumDleBaseURL)\(config.account)/\(config.profile)/\(LocationKey.fileName).json"
    }
    init(geofenceConfiguration config: TealiumConfig) {
        switch config.initializeGeofenceDataFrom {
        case .tealium:
            self = .remote(Self.url(from: config))
        case .localFile(let string):
            self = .local(string)
        case .customUrl(let string):
            self = .remote(string)
        default:
            self = .none
        }
    }
}

#endif
