//
//  VisitorIdProvider.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 29/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class VisitorIdMap: Codable {
    var currentIdentity: String?
    var cachedIds: [String: String]
    init() {
        cachedIds = [:]
    }
}

class VisitorIdProvider {
    private let bag = TealiumDisposeBag()
    let identityListener: VisitorIdentityListener?
    let visitorIdMap: VisitorIdMap
    let storage: TealiumDiskStorage
    let onVisitorId: TealiumReplaySubject<String>
    init(context: TealiumContext, onVisitorId: TealiumReplaySubject<String>) {
        storage = TealiumDiskStorage(config: context.config, forModule: ModuleNames.appdata.lowercased() + ".visitorIdMap")
        visitorIdMap = storage.retrieve(as: VisitorIdMap.self) ?? VisitorIdMap()

        self.onVisitorId = onVisitorId

        guard let dataLayer = context.dataLayer,
           let identityKey = context.config.visitorIdentityKey else {
            self.identityListener = nil
            return
        }
        let identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        self.identityListener = identityListener

        var currentVisitorId: String?
        onVisitorId.subscribe({ [weak self] visitorId in
            guard let self = self else { return }
            currentVisitorId = visitorId
            guard let lastIdentity = self.visitorIdMap.currentIdentity else { // First launch
                return
            }
            self.saveVisitorId(visitorId, forKey: lastIdentity)
        }).toDisposeBag(bag)
        onVisitorId.subscribeOnce { [weak self] firstVisitorId in // Just to wait for the first visitor to be dispatched
            guard let self = self else { return }
            identityListener.onNewIdentity.subscribe { [weak self] identity in
                guard let self = self else {
                    return
                }
                let oldIdentity = self.visitorIdMap.currentIdentity
                if oldIdentity != identity {
                    self.visitorIdMap.currentIdentity = identity
                }
                if let cachedVisitorId = self.getVisitorId(forKey: identity) {
                    if cachedVisitorId != currentVisitorId {
                        self.setVisitorId(cachedVisitorId) // Notify and Persist visitorId
                    } else {
                        self.persistStorage() // To just save the current identity
                    }
                } else if oldIdentity == nil { // first launch
                    self.saveVisitorId(currentVisitorId ?? firstVisitorId, forKey: identity) // currentVisitorId should never be nil anyway, firstVisitorId added just to compile
                } else {
                    self.resetVisitorId()
                }
            }.toDisposeBag(self.bag)
        }
    }

    func clearStoredVisitorIds() {
        storage.delete(completion: nil)
    }

    func saveVisitorId(_ id: String, forKey key: String) {
        if let hashedKey = id.sha256() {
            visitorIdMap.cachedIds[key] = hashedKey
        }
        persistStorage()
    }

    func getVisitorId(forKey key: String) -> String? {
        guard let hashedKey = key.sha256() else {
             return nil
        }
        return visitorIdMap.cachedIds[hashedKey]
    }

    /// Resets Tealium Visitor Id
    /// - returns: the newly created visitorId
    @discardableResult
    func resetVisitorId() -> String {
        let id = self.visitorId(from: UUID().uuidString)
        setVisitorId(id)
        return id
    }

    private func setVisitorId(_ visitorId: String) {
        onVisitorId.publish(visitorId)
    }

    /// Converts UUID to Tealium Visitor ID format.
    ///
    /// - Parameter from: `String` containing a UUID
    /// - Returns: `String` containing Tealium Visitor ID
    func visitorId(from uuid: String) -> String {
        return uuid.replacingOccurrences(of: "-", with: "")
    }

    private func persistStorage() {
        storage.save(visitorIdMap, completion: nil)
    }
}
