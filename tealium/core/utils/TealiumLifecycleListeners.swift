//
//  LifecycleListeners.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(macOS)
#else
import UIKit
#endif

public class TealiumLifecycleListeners {

    @ToAnyObservable(TealiumBufferedSubject<Date>(bufferSize: 10))
    public var launchSubject: TealiumObservable<Date>

    public var sleepSubject = TealiumPublishSubject<Void>()
    public var wakeSubject = TealiumPublishSubject<Void>()
//    @ToAnyObservable(TealiumBufferedSubject(bufferSize: 10))
//    public var sleepSubject: TealiumObservable<Void>
//
//    @ToAnyObservable(TealiumBufferedSubject(bufferSize: 10))
//    public var wakeSubject: TealiumObservable<Void>

    var wakeNotificationObserver: NSObjectProtocol?
    var sleepNotificationObserser: NSObjectProtocol?

    public init() {
        addListeners()
        launch()
    }

    /// Notifies listeners of a launch event.
    public func launch() {
        let launchDate = Date()
        _launchSubject.publish(launchDate)
    }

    /// Notifies listeners of a sleep event.
    public func sleep() {
        sleepSubject.publish()
    }

    /// Notifies listeners of a wake event.
    public func wake() {
        wakeSubject.publish()
    }

    /// Sets up notification listeners to trigger events in listening delegates.
    func addListeners() {
        #if TEST
        #else
        #if os(watchOS)
        #else
        #if os(macOS)
        #else
        // swiftlint:disable identifier_name
        let notificationNameApplicationDidBecomeActive = UIApplication.didBecomeActiveNotification
        let notificationNameApplicationWillResignActive = UIApplication.willResignActiveNotification
        // swiftlint:enable identifier_name

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = TealiumQueues.backgroundSerialQueue

        wakeNotificationObserver = NotificationCenter.default.addObserver(forName: notificationNameApplicationDidBecomeActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?.wake()
        }

        sleepNotificationObserser = NotificationCenter.default.addObserver(forName: notificationNameApplicationWillResignActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?.sleep()
        }

        #endif
        #endif
        #endif
    }

    deinit {
        sleepNotificationObserser = nil
        wakeNotificationObserver = nil
    }

}
