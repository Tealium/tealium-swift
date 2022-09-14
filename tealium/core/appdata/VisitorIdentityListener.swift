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

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject<String>())
    public var onNewIdentity: TealiumObservable<String>

    init(dataLayer: DataLayerManagerProtocol, visitorIdentityKey: String) {
        self.evaluateData(data: dataLayer.all, for: visitorIdentityKey)
        dataLayer.onDataUpdated.subscribe({ [weak self] data in
            self?.evaluateData(data: data, for: visitorIdentityKey)
        }).toDisposeBag(bag)
    }

    private func evaluateData(data: [String: Any], for key: String) {
        if let value = data[key] {
            let stringValue = String(describing: value)
            if stringValue != $onNewIdentity.last() && !stringValue.isEmpty {
                _onNewIdentity.publish(stringValue)
            }
        }
    }
}
