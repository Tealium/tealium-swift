//
//  TealiumInstanceManager.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumInstanceManager {

    public lazy var tealiumInstances = [String: Tealium]()

    public static var shared = TealiumInstanceManager()

    private init() {

    }

    /// - Parameter instance: `Tealium` instance to be added to the Instance Manager￼
    /// - Parameter config: `TealiumConfig` for this instance from which to generate the instance key
    func addInstance(_ instance: Tealium, config: TealiumConfig) {
        let instanceKey = generateInstanceKey(for: config)
        tealiumInstances[instanceKey] = instance
    }

    /// Disables the specified instance. If there are no other references elsewhere in the app, the instances will be destroyed.
    /// - Parameter config: `TealiumConfig` for the instance
    public func removeInstance(config: TealiumConfig) {
        let instanceKey = generateInstanceKey(for: config)
        tealiumInstances[instanceKey] = nil
    }

    /// Disables the specified instance. If there are no other references elsewhere in the app, the instances will be destroyed.
    /// - Parameter instanceKey: `String` containing the instance name. Default `account.profile.environment`.
    public func removeInstanceForKey(_ instanceKey: String) {
        tealiumInstances[instanceKey] = nil
    }

    /// - Parameter instanceKey: `String` containing the instance key for the requested instance
    /// - Returns: `Tealium?` instance
    public func getInstanceByName(_ instanceKey: String) -> Tealium? {
        if let instance = tealiumInstances[instanceKey] {
            return instance
        }
        return nil
    }

    /// Disables all instances. If there are no other references elsewhere in the app, the instances will be destroyed.
    public func disable() {
        self.tealiumInstances = [String: Tealium]()
    }

    func generateInstanceKey(for config: TealiumConfig) -> String {
        return "\(config.account).\(config.profile).\(config.environment)"
    }

}
