//
//  TealiumModuleConfig.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

/**
    Configuration struct for TealiumModule subclasses.
 
 */
open class TealiumModuleConfig: CustomStringConvertible {

    let name: String
    let priority: UInt
    let build: UInt
    var enabled: Bool
    public var description: String {
        return "\(name).moduleConfig.priority:\(priority).enabled:\(enabled)))"
    }

    public init(name: String,
                priority: UInt,
                build: UInt,
                enabled: Bool) {

        self.name = name
        self.priority = priority
        self.build = build
        self.enabled = enabled
    }

}

extension TealiumModuleConfig: Equatable {
    public static func == (lhs: TealiumModuleConfig, rhs: TealiumModuleConfig ) -> Bool {
        if lhs.name != rhs.name {
            return false
        }

        if lhs.priority != rhs.priority {
            return false
        }

        if lhs.build != rhs.build {
            return false
        }

        if lhs.enabled != rhs.enabled {
            return false
        }

        return true
    }
}
