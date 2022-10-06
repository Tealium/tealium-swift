//
//  VisitorIdProvider.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 29/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class VisitorIdProvider {
    private let bag = TealiumDisposeBag()
    let identityListener: VisitorIdentityListener?
    var visitorIdStorage: VisitorIdStorage
    let diskStorage: TealiumDiskStorageProtocol
    @ToAnyObservable<TealiumReplaySubject<String>>(TealiumReplaySubject<String>())
    var onVisitorId: TealiumObservable<String>

    init(config: TealiumConfig, dataLayer: DataLayerManagerProtocol?, diskStorage: TealiumDiskStorageProtocol? = nil, visitorIdMigrator: VisitorIdMigratorProtocol? = nil) {
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "VisitorIdStorage")
        guard let dataLayer = dataLayer else {
            self.identityListener = nil
            self.visitorIdStorage = Self.newVisitorIdStorage()
            return
        }
        if let identityKey = config.visitorIdentityKey {
            self.identityListener = VisitorIdentityListener(dataLayer: dataLayer,
                                                            visitorIdentityKey: identityKey)
        } else {
            self.identityListener = nil
        }
        let migrator = visitorIdMigrator ?? VisitorIdMigrator(dataLayer: dataLayer,
                                                              config: config)
        if let oldData = migrator.getOldPersistentData() {
            self.visitorIdStorage = VisitorIdStorage(visitorId: oldData.visitorId)
            dataLayer.add(key: TealiumDataKey.uuid, value: oldData.uuid, expiry: .forever)
            persistStorage()
            migrator.deleteOldPersistentData()
        } else if let storage = self.diskStorage.retrieve(as: VisitorIdStorage.self) {
            self.visitorIdStorage = storage
        } else {
            self.visitorIdStorage = Self.newVisitorIdStorage(config: config)
            persistStorage()
        }
        if dataLayer.all[TealiumDataKey.uuid] == nil {
            dataLayer.add(key: TealiumDataKey.uuid,
                          value: UUID().uuidString,
                          expiry: .forever)
        }
        publishVisitorId(visitorIdStorage.visitorId, andUpdateStorage: false)
        handleIdentitySwitch()
    }

    func handleIdentitySwitch() {
        identityListener?.onNewIdentity.subscribe { [weak self] identity in
            guard let self = self,
                  let identity = identity.sha256() else {
                return
            }
            let oldIdentity = self.visitorIdStorage.currentIdentity
            guard oldIdentity != identity else { return }
            self.visitorIdStorage.currentIdentity = identity
            let isFirstLaunchWithVisitorSwitching = oldIdentity == nil
            if let cachedVisitorId = self.getVisitorId(forKey: identity) {
                if cachedVisitorId != self.visitorIdStorage.visitorId {
                    self.publishVisitorId(cachedVisitorId, andUpdateStorage: true)
                } else {
                    self.persistStorage() // To just save the current identity
                }
            } else if isFirstLaunchWithVisitorSwitching {
                self.visitorIdStorage.setCurrentVisitorIdForCurrentIdentity()
                self.persistStorage()
            } else {
                self.resetVisitorId()
            }
        }.toDisposeBag(self.bag)
    }

    func clearStoredVisitorIds() {
        diskStorage.delete(completion: nil)
        visitorIdStorage = Self.newVisitorIdStorage()
        publishVisitorId(visitorIdStorage.visitorId, andUpdateStorage: true)
        identityListener?.reset()
    }

    static func newVisitorIdStorage(config: TealiumConfig? = nil) -> VisitorIdStorage {
        VisitorIdStorage(visitorId: config?.existingVisitorId ?? Self.visitorId(from: UUID().uuidString))
    }

    func getVisitorId(forKey hashedKey: String) -> String? {
        return visitorIdStorage.cachedIds[hashedKey]
    }

    /// Resets Tealium Visitor Id
    /// - returns: the newly created visitorId
    @discardableResult
    func resetVisitorId() -> String {
        let id = Self.visitorId(from: UUID().uuidString)
        publishVisitorId(id, andUpdateStorage: true)
        return id
    }

    /// Always use this method to publish new visitor IDs so we can also persist them
    func publishVisitorId(_ visitorId: String, andUpdateStorage shouldUpdate: Bool) {
        _onVisitorId.publish(visitorId)
        if shouldUpdate {
            visitorIdStorage.setVisitorIdForCurrentIdentity(visitorId)
            persistStorage()
        }
    }

    /// Converts UUID to Tealium Visitor ID format.
    ///
    /// - Parameter from: `String` containing a UUID
    /// - Returns: `String` containing Tealium Visitor ID
    static func visitorId(from uuid: String) -> String {
        return uuid.replacingOccurrences(of: "-", with: "")
    }

    private func persistStorage() {
        diskStorage.save(visitorIdStorage, completion: nil)
    }
}
