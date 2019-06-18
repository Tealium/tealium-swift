//
//  TealiumSaveDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/14/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumSaveDelegate: class {

    /// Initiates a save request to store persistent data
    ///
    /// - Parameter data: [String: Any] of data to be stored
    func savePersistentData(data: [String: Any])
}
