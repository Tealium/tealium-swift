//
//  ObservableTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 01/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class ObservableTests: XCTestCase {
    
    @ToAnyObservable(TealiumReplaySubject<Void>())
    var onReady: TealiumObservable<Void>
    
    @ToAnyObservable(TealiumPublisher<Int>())
    public var pubObservable: TealiumObservable<Int>
    
    @ToAnyObservable(TealiumPublishSubject<Int>())
    var subObservable: TealiumObservable<Int>
    
    @ToAnyObservable(TealiumReplaySubject<Int>())
    var behaviorObservable: TealiumObservable<Int>
    
    @ToAnyObservable(TealiumBufferedSubject<Int>())
    var bufferedObservable: TealiumObservable<Int>
    
    override func setUpWithError() throws {
        helper = RetaiCycleHelper(publisher: TealiumPublisher<Int>()) {
            
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // PropertyWrappers
    
    func testOnReady() {
        let readyNotifiedBefore = XCTestExpectation()
        let readyNotifiedAfter = XCTestExpectation()
        onReady.subscribe { _ in
            readyNotifiedBefore.fulfill()
        }
        _onReady.publish()
        onReady.subscribe { _ in
            readyNotifiedAfter.fulfill()
        }
        wait(for: [readyNotifiedBefore,readyNotifiedAfter], timeout: 0)
    }

    func testPublisherPropertyWrapper() {
        let eventNotified = XCTestExpectation()
        let value = 2
        pubObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _pubObservable.publish(value)
        
        wait(for: [eventNotified], timeout: 0)
    }
    
    func testSubjectPropertyWrapper() {
        let eventNotified = XCTestExpectation()
        let value = 2
        subObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _subObservable.publish(value)
        
        wait(for: [eventNotified], timeout: 0)
    }
    
    func testBehaviorSubjectPropertyWrapper() {
        let eventNotified = XCTestExpectation()
        let value = 2
        behaviorObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _behaviorObservable.publish(value)
        
        wait(for: [eventNotified], timeout: 0)
    }
    
    func testBufferedSubjectPropertyWrapper() {
        let eventNotified = XCTestExpectation()
        let value = 2
        bufferedObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _bufferedObservable.publish(value)
        
        wait(for: [eventNotified], timeout: 0)
    }
    
    // Publishers/Subjects
    
    func testPublisher() {
        let eventNotified = XCTestExpectation()
        let value = 2
        let publisher = TealiumPublisher<Int>()
        let observable = publisher.asObservable()
        observable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        publisher.publish(value)
        
        wait(for: [eventNotified], timeout: 0)
    }
    
    func testPublishSubject() {
        let eventNotified = XCTestExpectation()
        let value = 2
        let subject = TealiumPublishSubject<Int>()
        subject.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        subject.publish(value)
        wait(for: [eventNotified], timeout: 0)
    }
    
    func testReplaySubject() {
        let eventNotified = XCTestExpectation()
        let pastEventNotified = XCTestExpectation(description: "Past events get notified on new subscriptions")
        let expiredEventNotified = XCTestExpectation(description: "Older events should be removed from cache when the cache is full and new events come in")
        expiredEventNotified.isInverted = true
        let value = 2
        let subject = TealiumReplaySubject<Int>()
        subject.subscribe { val in
            if (val == value) {
                eventNotified.fulfill()
            }
        }
        subject.publish(value)
        
        XCTAssertEqual(value, subject.last())
        
        // Later subscription also receive past events
        subject.subscribe { val in
            if (val == value) {
                pastEventNotified.fulfill()
            }
        }
        let newValue = 3
        subject.publish(newValue)
        subject.subscribe { val in
            if (val == newValue) {
                pastEventNotified.fulfill()
            }
            if (val == value) {
                expiredEventNotified.fulfill()
            }
            
        }
        wait(for: [eventNotified, pastEventNotified, expiredEventNotified], timeout: 0)
    }
    
    func testBufferedSubject() {
        let eventNotified = XCTestExpectation()
        let newEventsNotifiedOnOldSubscription = XCTestExpectation(description: "New events get notified on new subscriptions")
        let newEventsNotified = XCTestExpectation(description: "New events get notified on new subscriptions")
        let expiredEventNotified = XCTestExpectation(description: "Older events should be removed from cache when the cache is full and new events come in")
        expiredEventNotified.isInverted = true
        let value = 2
        let newValue = 3
        let subject = TealiumBufferedSubject<Int>()
        
        subject.publish(value)
        
        // First subscription receives all events
        subject.subscribe { val in
            if (val == value) {
                eventNotified.fulfill()
            }
            if (val == newValue) {
                newEventsNotifiedOnOldSubscription.fulfill()
            }
        }
        
        // Later subscription DONT receive past events, only new ones
        subject.subscribe { val in
            if (val == value) {
                expiredEventNotified.fulfill()
            }
            if (val == newValue) {
                newEventsNotified.fulfill()
            }
        }
        subject.publish(newValue)
        wait(for: [eventNotified, newEventsNotified, expiredEventNotified, newEventsNotifiedOnOldSubscription], timeout: 0)
    }
    
    // Dispose
    
    func testSubscriptionDispose() {
        
        let eventNotified = XCTestExpectation()
        let eventNotNotified = XCTestExpectation()
        eventNotNotified.isInverted = true
        let subscription = pubObservable.subscribe { val in
            if (val == 1) {
                eventNotified.fulfill()
            }
            if (val == 2) {
                eventNotNotified.fulfill()
            }
        }
        _pubObservable.publish(1)
        subscription.dispose()
        _pubObservable.publish(2)
        wait(for: [eventNotified, eventNotNotified], timeout: 0)
    }
    
    func testUnsubscribe() {
        
        let eventNotified = XCTestExpectation()
        let eventNotNotified = XCTestExpectation()
        eventNotNotified.isInverted = true
        let subscription = pubObservable.subscribe { val in
            if (val == 1) {
                eventNotified.fulfill()
            }
            if (val == 2) {
                eventNotNotified.fulfill()
            }
        }
        _pubObservable.publish(1)
        pubObservable.unsubscribe(subscription)
        _pubObservable.publish(2)
        wait(for: [eventNotified, eventNotNotified], timeout: 0)
    }

    
    func testDeinitDisposeBag() {
        
        let eventNotified = XCTestExpectation()
        let eventNotNotified = XCTestExpectation()
        eventNotNotified.isInverted = true
        var disposeBag = TealiumDisposeBag()
        pubObservable.subscribe { val in
            if (val == 1) {
                eventNotified.fulfill()
            }
            if (val == 2) {
                eventNotNotified.fulfill()
            }
        }.toDisposeBag(disposeBag)
        
        _pubObservable.publish(1)
        disposeBag = TealiumDisposeBag()
        _pubObservable.publish(2)
        
        wait(for: [eventNotified, eventNotNotified], timeout: 0)
    }
    
    func testDisposeDisposeBag() {
        
        let eventNotified = XCTestExpectation()
        let eventNotNotified = XCTestExpectation()
        eventNotNotified.isInverted = true
        let disposeBag = TealiumDisposeBag()
        pubObservable.subscribe { val in
            if (val == 1) {
                eventNotified.fulfill()
            }
            if (val == 2) {
                eventNotNotified.fulfill()
            }
        }.toDisposeBag(disposeBag)
        
        _pubObservable.publish(1)
        disposeBag.dispose()
        _pubObservable.publish(2)
        
        wait(for: [eventNotified, eventNotNotified], timeout: 0)
    }
    
    // Deinit
    var helper: RetaiCycleHelper<TealiumPublisher<Int>>?
    
    func testRetainCycle() {
        let neverDeinit = XCTestExpectation()
        neverDeinit.isInverted = true
        helper?.onDeinit = {
            neverDeinit.fulfill()
        }
        helper = nil
        wait(for: [neverDeinit], timeout: 0)
    }
    
    func testDinitAfterUnsubscribe() {
        let deinitExpectation = XCTestExpectation()
        helper?.onDeinit = {
            deinitExpectation.fulfill()
        }
        helper?.subscription?.dispose()
        helper = nil
        wait(for: [deinitExpectation], timeout: 0)
    }

}


class RetaiCycleHelper<P: TealiumPublisherProtocol> {
    
    
    let anyPublisher: P
    var onDeinit: (() -> ())
    var subscription: TealiumSubscription<P.Element>?
    
    init(publisher: P, onDeinit: @escaping () -> ()) {
        self.anyPublisher = publisher
        self.onDeinit = onDeinit
        
        self.subscription = publisher.asObservable().subscribe { elem in
            print(self)
        }
    }
    
    deinit {
        onDeinit()
    }
    
}
