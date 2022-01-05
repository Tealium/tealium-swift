//
//  LegacyStorageProtocols.swift
//  TealiumCore
//
//  Created by Christina S on 10/12/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Storable {
    func object(forKey defaultName: String) -> Any?
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: Storable { }

public protocol Unarchivable {
    func setClass(_ cls: AnyClass?, forClassName codedName: String)
    func decodeObject(of classes: [AnyClass]?, forKey key: String) -> Any?
}

extension NSKeyedUnarchiver: Unarchivable { }
