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
        self.valuateData(data: dataLayer.all, for: visitorIdentityKey)
        dataLayer.onNewDataAdded.subscribe({ [weak self] data in
            self?.valuateData(data: data, for: visitorIdentityKey)
        }).toDisposeBag(bag)
    }

    private func valuateData(data: [String: Any], for key: String) {
        if let value = data[key] {
            let stringValue = String(describing: value)
            if stringValue != $onNewIdentity.last() {
                _onNewIdentity.publish(stringValue)
            }
        }
    }
}
