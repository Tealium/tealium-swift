//
//  Observable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 01/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol AnyPublisher {
    associatedtype Element
    func publish(_ element: Element)
    func toAnyObservable() -> Observable<Element>
}

public extension AnyPublisher where Element == Void {
    func publish() {
        self.publish(())
    }
}

class BufferedObservable<Element>: Observable<Element> {
    let bufferSize: Int?
    var buffer = [Element]()
    init(bufferSize: Int? = 1) {
        self.bufferSize = bufferSize
    }
    
    @discardableResult
    override func subscribe(_ observer: @escaping Observer) -> Subscription<Element> {
        let buffer = buffer
        self.buffer = []
        for element in buffer {
            observer(element)
        }
        return super.subscribe(observer)
    }
    
    override fileprivate func publish(_ element: Element) {
        if self.observers.isEmpty {
            while let size = bufferSize, buffer.count >= size && buffer.count > 0 {
                buffer.remove(at: 0)
            }
            if bufferSize == nil || bufferSize! > 0 {
                buffer.append(element)
            }
        }
        super.publish(element)
    }
    
}

class BehaviorObservable<Element>: Observable<Element> {
    let cacheSize: Int?
    var cache = [Element]()
    init(cacheSize: Int? = 1) {
        self.cacheSize = cacheSize
    }
    
    @discardableResult
    override func subscribe(_ observer: @escaping Observer) -> Subscription<Element> {
        let cache = cache
        for element in cache {
            observer(element)
        }
        return super.subscribe(observer)
    }
    
    override fileprivate func publish(_ element: Element) {
        while let size = cacheSize, cache.count >= size && cache.count > 0 {
            cache.remove(at: 0)
        }
        if cacheSize == nil || cacheSize! > 0 {
            cache.append(element)
        }
        super.publish(element)
    }
    
    func last() -> Element? {
        return cache.last
    }
}

public class Observable<Element> {
    public typealias Observer = (Element) -> ()
    private let uuid = UUID().uuidString
    private var count = 0
    fileprivate var observers = [String:Observer]()
    
    fileprivate init() {}
    
    @discardableResult
    public func subscribe(_ observer: @escaping Observer) -> Subscription<Element> {
        count += 1
        let key = uuid + String(count)
        observers[key] = observer
        return Subscription(self, key: key)
    }
    
    @discardableResult
    public func unsubscribe(_ subscription: Subscription<Element>) -> Bool {
        let key = subscription.key
        if observers[key] != nil {
            observers.removeValue(forKey: key)
            return true
        }
        return false
    }
    
    fileprivate func publish(_ element: Element) {
        let observers = observers.values
        for observer in observers {
            observer(element)
        }
    }
    
}

public class Publisher<Element>: AnyPublisher {
    
    fileprivate let observable: Observable<Element>
    
    fileprivate init(_ obs: Observable<Element>) {
        self.observable = obs
    }
    
    convenience public init() {
        self.init(Observable<Element>())
    }
    
    public func publish(_ element: Element) {
        observable.publish(element)
    }
    
    public func toAnyObservable() -> Observable<Element> {
        return observable
    }
}


public class Subject<Element>: Publisher<Element> {
    
    public typealias Observer = (Element) -> ()
    
    @discardableResult
    public func subscribe(_ observer: @escaping Observer) -> Subscription<Element> {
        observable.subscribe(observer)
    }
    
    @discardableResult
    public func unsubscribe(_ subscription: Subscription<Element>) -> Bool {
        observable.unsubscribe(subscription)
    }
}

public class BehaviorSubject<Element>: Subject<Element> {
    
    
    public init(cacheSize: Int? = 1) {
        super.init(BehaviorObservable<Element>(cacheSize: cacheSize))
    }
    
    public func last() -> Element? {
        (self.observable as? BehaviorObservable<Element>)?.last()
    }
    
}

public class BufferedSubject<Element>: Subject<Element> {
    
    public init(bufferSize: Int? = 1) {
        super.init(BufferedObservable<Element>(bufferSize: bufferSize))
    }
}

public class DisposeBag: AnyDisposable {
    
    private var disposables = [AnyDisposable]()
    
    public init() {}
    
    public func add(_ disposable: AnyDisposable) {
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

public protocol AnyDisposable {
    func dispose()
}

public class Subscription<T>: AnyDisposable {
    
    private weak var observable: Observable<T>?
    fileprivate var key: String
    fileprivate init(_ observable: Observable<T>, key: String) {
        self.observable = observable
        self.key = key
    }
    
    public func dispose() {
        observable?.unsubscribe(self)
    }
    
    public func toDisposeBag(_ disposeBag: DisposeBag) {
        disposeBag.add(self)
    }
}

@propertyWrapper
public final class ToAnyObservable<P: AnyPublisher>: AnyPublisher {
    
    private let publisher: P
    public init(_ anyPublisher: P) {
        self.publisher = anyPublisher
    }
    
    public func publish(_ element: P.Element) {
        publisher.publish(element)
    }
    
    public var wrappedValue: Observable<P.Element> {
        return toAnyObservable()
    }
    
    public func toAnyObservable() -> Observable<P.Element> {
        return publisher.toAnyObservable()
    }
}
