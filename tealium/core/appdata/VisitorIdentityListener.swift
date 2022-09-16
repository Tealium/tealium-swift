//
//  VisitorIdentityListener.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class VisitorIdentityListener {
    private let bag = TealiumDisposeBag()
    private let dataLayer: DataLayerManagerProtocol
    private let identityKey: String

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject<String>())
    public var onNewIdentity: TealiumObservable<String>

    init(dataLayer: DataLayerManagerProtocol, visitorIdentityKey: String) {
        self.dataLayer = dataLayer
        self.identityKey = visitorIdentityKey
        reset()
    }

    private func evaluateData(data: [String: Any], for key: String) {
        if let value = data[key] {
            let stringValue = String(describing: value)
            if stringValue != $onNewIdentity.last() && !stringValue.isEmpty {
                _onNewIdentity.publish(stringValue)
            }
        }
    }

    func reset() {
        $onNewIdentity.clear()
        self.evaluateData(data: dataLayer.all, for: identityKey)
        dataLayer.onDataUpdated.subscribe({ [weak self] data in
            guard let self = self else { return }
            self.evaluateData(data: data, for: self.identityKey)
        }).toDisposeBag(bag)
    }
}
