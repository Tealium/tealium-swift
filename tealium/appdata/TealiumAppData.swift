//
//  TealiumAppData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumAppDataCollection {
    func name(bundle: Bundle) -> String?

    func rdns(bundle: Bundle) -> String?

    func version(bundle: Bundle) -> String?

    func build(bundle: Bundle) -> String?
}

protocol TealiumAppDataProtocol {
    func add(data: [String: Any])

    func getData() -> [String: Any]

    func setNewAppData()

    func setLoadedAppData(data: [String: Any])

    func deleteAllData()
}

public protocol TealiumSaveDelegate: class {
    func savePersistentData(data: [String: Any])
}

public class TealiumAppData: TealiumAppDataProtocol, TealiumAppDataCollection {

    private(set) var uuid: String?
    weak var delegate: TealiumSaveDelegate?
    private let bundle = Bundle.main
    private var appData = [String: Any]()

    init(delegate: TealiumSaveDelegate) {
        self.delegate = delegate
    }

    /**
     Public constructor to enable other modules to use TealiumAppDataCollection protocol
     */
    public init() {
    }

    /**
     Add app data to all dispatches for the remainder of an active session.
     
     - parameters:
     - data: A [String: Any] dictionary. Values should be of type String or [String]
     */
    func add(data: [String: Any]) {
        appData += data
    }

    /**
     Retrieve a copy of app data used with dispatches.
     
     - returns: `[String: Any]`
     */
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

    // MARK: 
    // MARK: INTERNAL
    /**
     Checks if persistent keys are missing from the `data` dictionary
     - parameter data: The dictionary to check
     
     - TealiumAppDataKey.uuid
     - TealiumAppDataKey.visitorId
     
     - returns: Bool
     */
    class func isMissingPersistentKeys(data: [String: Any]) -> Bool {
        if data[TealiumAppDataKey.uuid] == nil { return true }
        if data[TealiumAppDataKey.visitorId] == nil { return true }
        return false
    }

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
            TealiumAppDataKey.visitorId: vid
        ]

        return data as [String: Any]
    }

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

    func setNewAppData() {
        let newUuid = UUID().uuidString
        appData = newPersistentData(for: newUuid)
        appData += newVolatileData()
        delegate?.savePersistentData(data: appData)
        uuid = newUuid
    }

    func setLoadedAppData(data: [String: Any]) {
        appData = data
        appData += newVolatileData()
    }
}

public extension TealiumAppDataCollection {
    func name(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    func rdns(bundle: Bundle) -> String? {
        return bundle.bundleIdentifier
    }

    func version(bundle: Bundle) -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    func build(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}
