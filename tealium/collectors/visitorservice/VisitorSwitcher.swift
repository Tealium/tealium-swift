//
//  VisitorSwitcher.swift
//  TealiumVisitorService
//
//  Created by Enrico Zannini on 24/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public extension TealiumConfigKey {
    static let visitorIdentityKey = "visitorIdentityKey"
}

public extension TealiumConfig {
    var visitorIdentityKey: String? {
        get {
            return options[TealiumConfigKey.visitorIdentityKey] as? String
        }
        set {
            options[TealiumConfigKey.visitorIdentityKey] = newValue
        }
    }
}

protocol VisitorSwitcherDelegate: AnyObject {
    func resetVisitorId()
    func setVisitorId(_ visitorId: String)
}

class VisitorSwitcher {
    private let bag = TealiumDisposeBag()
    let identityListener: VisitorIdentityListener
    weak var delegate: VisitorSwitcherDelegate?
    init?(context: TealiumContext, delegate: VisitorSwitcherDelegate?) {
        guard let dataLayer = context.dataLayer,
                let identityKey = context.config.visitorIdentityKey else {
            return nil
        }
        self.delegate = delegate
        identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        var lastIdentity: String?
        var currentVisitorId: String?
        identityListener.onNewIdentity.subscribe { [weak self] identity in
            guard lastIdentity != identity, let self = self else { return }
            lastIdentity = identity
            if let savedVisitorId = self.getVisitorId(forKey: identity) {
                delegate?.setVisitorId(savedVisitorId)
            } else {
                delegate?.resetVisitorId() // this will automatically trigger a visitorId update and therefore a save
            }
        }.toDisposeBag(bag)
        context.onVisitorId?.subscribe({ [weak self] visitorId in
            guard currentVisitorId != visitorId, let self = self else { return }
            currentVisitorId = visitorId
            guard let lastIdentity = lastIdentity else {
                return
            }
            self.saveVisitorId(visitorId, forKey: lastIdentity)
        }).toDisposeBag(bag)
    }
    
    func clearStoredVisitorIds() {
        // delete the storage
    }
    
    func saveVisitorId(_ id: String, forKey key: String) {
        // hash key
        // save {hashedKey:id}
    }
    
    func getVisitorId(forKey key: String) -> String? {
        // Hash key
        // get visitorId for key
        return nil
    }
}

class VisitorIdentityListener {
    private let bag = TealiumDisposeBag()

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject<String>())
    public var onNewIdentity: TealiumObservable<String>

    init(dataLayer: DataLayerManagerProtocol, visitorIdentityKey: String) {
        self.valuateData(data: dataLayer.all, for: visitorIdentityKey)
        dataLayer.onNewDataAdded.subscribe({ [weak self] data in
            self?.valuateData(data: data, for: visitorIdentityKey)
        }).toDisposeBag(bag)
    }

    private func valuateData(data: [String: Any], for key: String) {
        if let value = data[key] {
            _onNewIdentity.publish(String(describing: value))
        }
    }
}
