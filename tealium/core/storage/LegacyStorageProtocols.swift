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
    static func unarchiveTopLevelObjectWithData(_ data: Data) throws -> Any?
}

extension NSKeyedUnarchiver: Unarchivable { }
