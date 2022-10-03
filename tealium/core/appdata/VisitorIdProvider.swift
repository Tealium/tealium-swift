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
            migrator.deleteOldPersistentData()
        } else if let storage = self.diskStorage.retrieve(as: VisitorIdStorage.self) {
            self.visitorIdStorage = storage
        } else {
            self.visitorIdStorage = Self.newVisitorIdStorage(config: config)
        }
        if dataLayer.all[TealiumDataKey.uuid] == nil {
            dataLayer.add(key: TealiumDataKey.uuid, value: UUID().uuidString, expiry: .forever)
        }
        _onVisitorId.publish(visitorIdStorage.visitorId)
        onVisitorId.subscribe({ [weak self] visitorId in
            guard let self = self, self.visitorIdStorage.visitorId != visitorId else { return }
            self.visitorIdStorage.setVisitorIdForCurrentIdentity(visitorId)
            self.persistStorage()
        }).toDisposeBag(bag)
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
            let isFirstLaunch = oldIdentity == nil
            if let cachedVisitorId = self.getVisitorId(forKey: identity) {
                if cachedVisitorId != self.visitorIdStorage.visitorId {
                    self.setVisitorId(cachedVisitorId) // Notify and Persist the cachedVisitorId for the new current Identity
                } else {
                    self.persistStorage() // To just save the current identity
                }
            } else if isFirstLaunch {
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
        setVisitorId(visitorIdStorage.visitorId)
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
        setVisitorId(id)
        return id
    }

    private func setVisitorId(_ visitorId: String) {
        _onVisitorId.publish(visitorId)
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
