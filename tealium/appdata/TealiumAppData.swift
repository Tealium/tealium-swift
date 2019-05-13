//
//  TealiumAppData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if appdata
import TealiumCore
#endif

public class TealiumAppData: TealiumAppDataProtocol, TealiumAppDataCollection {

    private(set) var uuid: String?
    weak var delegate: TealiumSaveDelegate?
    private let bundle = Bundle.main
    private var appData = [String: Any]()

    init(delegate: TealiumSaveDelegate) {
        self.delegate = delegate
    }

    /// Public constructor to enable other modules to use TealiumAppDataCollection protocol
    public init() {
    }

    /// Add app data to all dispatches for the remainder of an active session.
    ///
    /// - Parameters:
    /// - data: A [String: Any] dictionary. Values should be of type String or [String]
    func add(data: [String: Any]) {
        appData += data
    }

    /// Retrieve a copy of app data used with dispatches.
    ///
    /// - Returns: `[String: Any]`
    func getData() -> [String: Any] {
        let data = appData
        return data
    }

    /// Deletes all app data.
    func deleteAllData() {
        appData.removeAll()
    }

    /// Returns total items
    var count: Int {
        return appData.count
    }

    // MARK: INTERNAL
    /// Checks if persistent keys are missing from the `data` dictionary
    /// - Parameter data: The dictionary to check
    ///
    /// - TealiumAppDataKey.uuid
    /// - TealiumAppDataKey.visitorId
    ///
    /// - Returns: Bool
    class func isMissingPersistentKeys(data: [String: Any]) -> Bool {
        if data[TealiumAppDataKey.uuid] == nil { return true }
        if data[TealiumAppDataKey.visitorId] == nil { return true }
        return false
    }

    /// Converts UUID to Tealium Visitor ID format
    ///
    /// - Parameter from: String containing a UUID
    /// - Returns: String containing Tealium Visitor ID
    func visitorId(from uuid: String) -> String {
        return uuid.replacingOccurrences(of: "-", with: "")
    }

    /// Prepares new Tealium default App related data. Legacy Visitor Id data
    /// is set here as it based off app_uuid.
    ///
    /// - Parameter uuid: The uuid string to use for new persistent data.
    /// - Returns: A [String:Any] dictionary.
    func newPersistentData(for uuid: String) -> [String: Any] {
        let vid = visitorId(from: uuid)

        let data = [
            TealiumAppDataKey.uuid: uuid,
            TealiumAppDataKey.visitorId: vid,
        ]

        return data as [String: Any]
    }

    /// Retrieves a new set of Volatile Data (usually once per app launch)
    ///
    /// - Returns: [String: Any] containing new volatile data (app name, rdns, version, build)
    func newVolatileData() -> [String: Any] {
        var result: [String: Any] = [:]

        if let name = name(bundle: bundle) {
            result[TealiumAppDataKey.name] = name
        }

        if let rdns = rdns(bundle: bundle) {
            result[TealiumAppDataKey.rdns] = rdns
        }

        if let version = version(bundle: bundle) {
            result[TealiumAppDataKey.version] = version
        }

        if let build = build(bundle: bundle) {
            result[TealiumAppDataKey.build] = build
        }

        return result
    }

    /// Stores current AppData in memory
    func setNewAppData() {
        let newUuid = UUID().uuidString
        appData = newPersistentData(for: newUuid)
        appData += newVolatileData()
        delegate?.savePersistentData(data: appData)
        uuid = newUuid
    }

    /// Populates in-memory AppData with existing values from persistent storage, if present
    ///
    /// - Parameter data: [String: Any] containing existing AppData variables
    func setLoadedAppData(data: [String: Any]) {
        appData = data
        appData += newVolatileData()
    }
}
