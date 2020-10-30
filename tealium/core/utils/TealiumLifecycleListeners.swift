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

    var listeningDelegates = TealiumMulticastDelegate<TealiumLifecycleEvents>()
    var hasLaunched = false
    var launchDate: Date?
    var wakeNotificationObserver: NSObjectProtocol?
    var sleepNotificationObserser: NSObjectProtocol?

    public init() {
        addListeners()
        launch()
    }

    /// Adds delegate to be notified of new events￼.
    ///
    /// - Parameter delegate:`TealiumLifecycleEvents` delegate
    public func addDelegate(delegate: TealiumLifecycleEvents) {
        listeningDelegates.add(delegate)
        if hasLaunched, let launchDate = launchDate {
            delegate.launch(at: launchDate)
        }
    }

    /// Removes a previously-added delegate￼.
    ///
    /// - Parameter delegate: `TealiumLifecycleEvents` delegate
    public func removeDelegate(delegate: TealiumLifecycleEvents) {
        listeningDelegates.remove(delegate)
    }

    /// Notifies listeners of a launch event.
    public func launch() {
        hasLaunched = true
        launchDate = Date()
        guard let launchDate = launchDate else {
            return
        }
        listeningDelegates.invoke {
            $0.launch(at: launchDate)
        }
    }

    /// Notifies listeners of a sleep event.
    public func sleep() {
        listeningDelegates.invoke {
            $0.sleep()
        }
    }

    /// Notifies listeners of a wake event.
    public func wake() {
        listeningDelegates.invoke {
            $0.wake()
        }
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

        wakeNotificationObserver = NotificationCenter.default.addObserver(forName: notificationNameApplicationDidBecomeActive, object: nil, queue: operationQueue) { _ in
            self.wake()
        }

        sleepNotificationObserser = NotificationCenter.default.addObserver(forName: notificationNameApplicationWillResignActive, object: nil, queue: operationQueue) { _ in
            self.sleep()
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
