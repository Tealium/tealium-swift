//
//  BackgroundTimeoutMediaBehaviorPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 14/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if media
import TealiumCore
#endif

public struct BackgroundTimeoutBehaviorPluginOption {

    let interval: Double

    public init(interval: Double) {
        self.interval = interval
    }
}

class BackgroundTimeoutMediaBehaviorPlugin: MediaSessionPlugin, BehaviorChangePluginFactoryWithOptions {
    typealias Options = BackgroundTimeoutBehaviorPluginOption

    static func create(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin {
        BackgroundTimeoutMediaBehaviorPlugin(dataProvider: dataProvider, notifier: notifier, options: options)
    }

    let bag = TealiumDisposeBag()
    let notifier: MediaSessionEventsNotifier
    let options: Options
    var isSessionResumed = false
    var isSessionEnded = false

    init(dataProvider: MediaSessionDataProvider, notifier: MediaSessionEventsNotifier, options: Options) {
        self.options = options
        self.notifier = notifier
        Tealium.lifecycleListeners.onBackgroundStateChange.subscribe { [weak self] state in
            guard let self = self else {
                return
            }
            switch state {
            case .wake:
                self.wake()
            case .sleep:
                self.sleep()
            }
        }.toDisposeBag(bag)
        notifier.onResumeSession.subscribe { [weak self] in
            self?.wake()
        }.toDisposeBag(bag)
    }

    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    public func sleep() {
        isSessionResumed = false
        #if os(iOS)
        var backgroundTaskId: UIBackgroundTaskIdentifier?
        backgroundTaskId = BackgroundTimeoutMediaBehaviorPlugin.sharedApplication?.beginBackgroundTask {
            if let taskId = backgroundTaskId {
                BackgroundTimeoutMediaBehaviorPlugin.sharedApplication?.endBackgroundTask(taskId)
                backgroundTaskId = .invalid
            }
        }
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + options.interval) {
            self.sendEndSessionInBackground()
        }

        if let taskId = backgroundTaskId {
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + (options.interval + 1.0)) {
                BackgroundTimeoutMediaBehaviorPlugin.sharedApplication?.endBackgroundTask(taskId)
                backgroundTaskId = .invalid
            }
        }
        #elseif os(watchOS)
        let pInfo = ProcessInfo()
        pInfo.performExpiringActivity(withReason: "Tealium Swift: End Media Session") { willBeSuspended in
            if !willBeSuspended {
                TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + options.interval) {
                    self.sendEndSessionInBackground()
                }
            }
        }
        #else
        sendEndSessionInBackground()
        #endif
    }

    public func wake() {
        if !isSessionEnded && !isSessionResumed {
            notifier.onResumeSession.publish()
        }
    }

    func sendEndSessionInBackground() {
        if !isSessionResumed {
            isSessionEnded = true
            notifier.onEndSession.publish()
        }
    }
}
