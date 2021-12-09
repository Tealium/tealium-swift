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

    public var launchSubject = TealiumReplaySubject<Date>()
    public var sleepSubject = TealiumReplaySubject<Void>()
    public var wakeSubject = TealiumReplaySubject<Void>()

    var wakeNotificationObserver: NSObjectProtocol?
    var sleepNotificationObserser: NSObjectProtocol?

    public init() {
        addListeners()
        launch()
    }

    /// Notifies listeners of a launch event.
    public func launch() {
        let launchDate = Date()
        launchSubject.publish(launchDate)
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
