//
//  PubSub.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumPublisherProtocol {
    func publish(_ element: Element) {
        asObservable().publish(element)
    }
}

public class TealiumObservable<Element>: TealiumObservableProtocol {
    private let uuid = UUID().uuidString
    private var count = 0
    fileprivate var observers = [String: Observer]()

    fileprivate init() {}

    @discardableResult
    public func subscribe(_ observer: @escaping Observer) -> TealiumSubscription<Element> {
        count += 1
        let key = uuid + String(count)
        observers[key] = observer
        return TealiumSubscription(self, key: key)
    }

    @discardableResult
    public func unsubscribe(_ subscription: TealiumSubscription<Element>) -> Bool {
        let key = subscription.key
        if observers[key] != nil {
            observers.removeValue(forKey: key)
            return true
        }
        return false
    }

    fileprivate func publish(_ element: Element) {
        let observers = self.observers.values
        for observer in observers {
            observer(element)
        }
    }

    public func asObservable() -> TealiumObservable<Element> {
        self
    }

}

public class TealiumSubscription<T>: TealiumDisposableProtocol {

    private weak var observable: TealiumObservable<T>?
    fileprivate var key: String
    fileprivate init(_ observable: TealiumObservable<T>, key: String) {
        self.observable = observable
        self.key = key
    }

    public func dispose() {
        observable?.unsubscribe(self)
    }

    public func toDisposeBag(_ disposeBag: TealiumDisposeBag) {
        disposeBag.add(self)
    }
}

public class TealiumPublisher<Element>: TealiumPublisherProtocol {

    fileprivate let observable: TealiumObservable<Element>

    fileprivate init(_ obs: TealiumObservable<Element>) {
        self.observable = obs
    }

    convenience public init() {
        self.init(TealiumObservable<Element>())
    }

    public func asObservable() -> TealiumObservable<Element> {
        return observable
    }
}

public class TealiumPublishSubject<Element>: TealiumPublisher<Element>, TealiumSubjectProtocol {
}

// MARK: Replay

public class TealiumReplayObservable<Element>: TealiumObservable<Element> {
    private let cacheSize: Int?
    private var cache = [Element]()
    fileprivate init(cacheSize: Int? = 1) {
        self.cacheSize = cacheSize
    }

    @discardableResult
    public override func subscribe(_ observer: @escaping Observer) -> TealiumSubscription<Element> {
        let cache = self.cache
        defer {
            for element in cache {
                observer(element)
            }
        }
        return super.subscribe(observer)
    }

    override fileprivate func publish(_ element: Element) {
        while let size = cacheSize, cache.count >= size && cache.count > 0 {
            cache.remove(at: 0)
        }
        if cacheSize == nil || cacheSize > 0 {
            cache.append(element)
        }
        super.publish(element)
    }

    public func clear() {
        cache.removeAll()
    }
    
    public func last() -> Element? {
        return cache.last
    }
}

public class TealiumReplaySubject<Element>: TealiumPublishSubject<Element> {

    public init(cacheSize: Int? = 1) {
        super.init(TealiumReplayObservable<Element>(cacheSize: cacheSize))
    }

    public func clear() {
        (observable as? TealiumReplayObservable<Element>)?.clear()
    }

    public func last() -> Element? {
        (observable as? TealiumReplayObservable<Element>)?.last()
    }

}

// MARK: Buffered

public class TealiumBufferedObservable<Element>: TealiumObservable<Element> {
    private let bufferSize: Int?
    private var buffer = [Element]()
    fileprivate init(bufferSize: Int? = 1) {
        self.bufferSize = bufferSize
    }

    @discardableResult
    override public func subscribe(_ observer: @escaping Observer) -> TealiumSubscription<Element> {
        let buffer = self.buffer
        self.buffer = []
        defer {
            for element in buffer {
                observer(element)
            }
        }
        return super.subscribe(observer)
    }

    override fileprivate func publish(_ element: Element) {
        if self.observers.isEmpty {
            while let size = bufferSize, buffer.count >= size && buffer.count > 0 {
                buffer.remove(at: 0)
            }
            if bufferSize == nil || bufferSize > 0 {
                buffer.append(element)
            }
        }
        super.publish(element)
    }

}

public class TealiumBufferedSubject<Element>: TealiumPublishSubject<Element> {

    public init(bufferSize: Int? = 1) {
        super.init(TealiumBufferedObservable<Element>(bufferSize: bufferSize))
    }
}

private extension Optional where Wrapped == Int {

    static func > (lhs: Int?, rhs: Int) -> Bool {
        if let value = lhs {
            return value > rhs
        }
        return false
    }

}
