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

public protocol ConsentUnarchiver {
    func decodeObject(fromData data: Data) throws -> Any?
}
