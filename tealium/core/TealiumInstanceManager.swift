//
//  TealiumInstanceManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 06/04/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumInstanceManager {

    lazy var tealiumInstances = [String: Tealium]()

    static let shared = TealiumInstanceManager()

    private init() {

    }

    public func addInstance(_ instance: Tealium, config: TealiumConfig) {
        let account = config.account
        let profile = config.profile
        let environment = config.environment
        let instanceKey = [account, profile, environment].joined(separator: ".")
        tealiumInstances[instanceKey] = instance
    }

    public func getInstances() -> [String: Tealium] {
        return tealiumInstances
    }

    public func getInstanceByName(_ instanceKey: String) -> Tealium? {
        if let instance = tealiumInstances[instanceKey] {
            return instance
        }
        return nil
    }

}
