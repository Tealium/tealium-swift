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

    @frozen
    public enum BackgroundState {
        case wake(date: Date)
        case sleep(date: Date)
    }

    public var launchDate = Date()

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject<BackgroundState>(cacheSize: 10))
    public var onBackgroundStateChange: TealiumObservable<BackgroundState>

    var wakeNotificationObserver: NSObjectProtocol?
    var sleepNotificationObserver: NSObjectProtocol?

    public init() {
        addListeners()
    }

    /// Notifies listeners of a sleep event.
    public func sleep() {
        _onBackgroundStateChange.publish(.sleep(date: Date()))
    }

    /// Notifies listeners of a wake event.
    public func wake() {
        _onBackgroundStateChange.publish(.wake(date: Date()))
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

        wakeNotificationObserver = NotificationCenter.default
            .addObserver(forName: notificationNameApplicationDidBecomeActive,
                         asyncOn: TealiumQueues.backgroundSerialQueue) { [weak self] _ in
                self?.wake()
            }

        sleepNotificationObserver = NotificationCenter.default
            .addObserver(forName: notificationNameApplicationWillResignActive,
                         asyncOn: TealiumQueues.backgroundSerialQueue) { [weak self] _ in
                self?.sleep()
            }

        #endif
        #endif
        #endif
    }

    deinit {
        sleepNotificationObserver = nil
        wakeNotificationObserver = nil
    }

}
