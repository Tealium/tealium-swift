//
//  SessionTrackingMediaSessionPlugin.swift
//  TealiumMedia
//
//  Created by Enrico Zannini on 08/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if media
import TealiumCore
#endif

public class SessionTrackingMediaSessionPlugin: MediaSessionPlugin, TrackingPluginFactory {
    let bag = TealiumDisposeBag()

    public static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> MediaSessionPlugin {
        SessionTrackingMediaSessionPlugin(dataProvider: dataProvider, events: events, tracker: tracker)
    }

    private init(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) {
        registerForEvents(dataProvider: dataProvider, events: events, tracker: tracker)
            .forEach { bag.add($0) }
    }

    private func registerForEvents(dataProvider: MediaSessionDataProvider, events: MediaSessionEvents2, tracker: MediaTracker) -> [TealiumDisposableProtocol] {
        [
            events.onStartSession.subscribe {
                tracker.requestTrack(.event(.sessionStart))
            },
            events.onResumeSession.subscribe {
                tracker.requestTrack(.event(.sessionResume))
            },
            events.onEndSession.subscribe {
                tracker.requestTrack(.event(.sessionEnd))
            }
        ]
    }
}

public struct BackgroundTimeoutBehaviorSessionPluginOption {

    let interval: Double

    public init(interval: Double) {
        self.interval = interval
    }
}

class BackgroundTimeoutBehaviorSessionPlugin: MediaSessionPlugin, BehaviorChangePluginFactoryWithOptions {
    typealias Options = BackgroundTimeoutBehaviorSessionPluginOption

    static func create(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, options: Options) -> MediaSessionPlugin {
        BackgroundTimeoutBehaviorSessionPlugin(dataProvider: dataProvider, events: events, options: options)
    }

    let bag = TealiumDisposeBag()
    let notifier: MediaSessionEventsNotifier
    let options: Options
    var isSessionResumed = false
    var isSessionEnded = false

    init(dataProvider: MediaSessionDataProvider, events: MediaSessionEventsNotifier, options: Options) {
        self.options = options
        self.notifier = events
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
        events.onResumeSession.subscribe { [weak self] in
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
        backgroundTaskId = BackgroundTimeoutBehaviorSessionPlugin.sharedApplication?.beginBackgroundTask {
            if let taskId = backgroundTaskId {
                BackgroundTimeoutBehaviorSessionPlugin.sharedApplication?.endBackgroundTask(taskId)
                backgroundTaskId = .invalid
            }
        }
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + options.interval) {
            self.sendEndSessionInBackground()
        }

        if let taskId = backgroundTaskId {
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + (options.interval + 1.0)) {
                BackgroundTimeoutBehaviorSessionPlugin.sharedApplication?.endBackgroundTask(taskId)
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
