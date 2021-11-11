//
//  Disposable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumDisposeBag: TealiumDisposableProtocol {

    private var disposables = [TealiumDisposableProtocol]()

    public init() {}

    public func add(_ disposable: TealiumDisposableProtocol) {
        disposables.append(disposable)
    }

    public func dispose() {
        let disposables = self.disposables
        self.disposables = []
        for disposable in disposables {
            disposable.dispose()
        }
    }

    deinit {
        dispose()
    }
}
