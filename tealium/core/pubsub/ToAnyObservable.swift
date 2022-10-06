//
//  ToAnyObservable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public final class ToAnyObservable<P: TealiumPublisherProtocol>: TealiumPublisherProtocol {
    private let publisher: P
    public init(_ anyPublisher: P) {
        self.publisher = anyPublisher
    }

    public var wrappedValue: TealiumObservable<P.Element> {
        return asObservable()
    }

    public func asObservable() -> TealiumObservable<P.Element> {
        return publisher.asObservable()
    }

    public var projectedValue: P {
        return publisher
    }
}
