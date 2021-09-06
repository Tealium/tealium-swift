//
//  Publisher.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumObservableConvertibleProtocol {
    associatedtype Element

    func asObservable() -> TealiumObservable<Element>
}

public protocol TealiumObservableProtocol: TealiumObservableConvertibleProtocol {
    typealias Observer = (Element) -> ()
    
    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> TealiumSubscription<Element>
    
    @discardableResult
    func unsubscribe(_ subscription: TealiumSubscription<Element>) -> Bool
}

public protocol TealiumPublisherProtocol: TealiumObservableConvertibleProtocol {
    func publish(_ element: Element)
}

public extension TealiumPublisherProtocol where Element == Void {
    func publish() {
        self.publish(())
    }
}

public protocol TealiumSubjectProtocol: TealiumObservableProtocol, TealiumPublisherProtocol {
    
}

extension TealiumSubjectProtocol {
    
    @discardableResult
    public func subscribe(_ observer: @escaping Observer) -> TealiumSubscription<Element> {
        asObservable().subscribe(observer)
    }
    
    @discardableResult
    public func unsubscribe(_ subscription: TealiumSubscription<Element>) -> Bool {
        asObservable().unsubscribe(subscription)
    }
}

public protocol TealiumDisposableProtocol {
    func dispose()
}
