//
//  TealiumAppDataProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/14/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

protocol TealiumAppDataProtocol {

    /// Add app data to all dispatches for the remainder of an active session.

    /// - Parameters:
    /// - data: A [String: Any] dictionary. Values should be of type String or [String]
    func add(data: [String: Any])

    /// Retrieve a copy of app data used with dispatches.
    ///
    /// - Returns: `[String: Any]`
    func getData() -> [String: Any]

    /// Stores current AppData in memory
    func setNewAppData()

    /// Populates in-memory AppData with existing values from persistent storage, if present
    ///
    /// - Parameter data: [String: Any] containing existing AppData variables
    func setLoadedAppData(data: [String: Any])

    /// Deletes all app data.
    func deleteAllData()
}
