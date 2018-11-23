//
//  TealiumInstanceManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 6/4/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumInstanceManager {

    public lazy var tealiumInstances = [String: Tealium]()

    public static let shared = TealiumInstanceManager()

    private init() {

    }

    func addInstance(_ instance: Tealium, config: TealiumConfig) {
        let account = config.account
        let profile = config.profile
        let environment = config.environment
        let instanceKey = [account, profile, environment].joined(separator: ".")
        tealiumInstances[instanceKey] = instance
    }

    public func getInstanceByName(_ instanceKey: String) -> Tealium? {
        if let instance = tealiumInstances[instanceKey] {
            return instance
        }
        return nil
    }

}
