//
//  TealiumRepeatingTimer.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/6/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

// Credit/source: https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9 🙏

import Foundation

/// Safe implementation of a repeating timer for scheduling connectivity checks
class TealiumRepeatingTimer {

    let timeInterval: TimeInterval
    let dispatchQueue: DispatchQueue

    /// - Parameters:
    /// - timeInterval: TimeInterval between runs of the timed event
    /// - dispatchQueue: The queue to use for the timer
    init(timeInterval: TimeInterval, dispatchQueue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.dispatchQueue = dispatchQueue
    }

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: dispatchQueue)
        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timer
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    /// Resumes this timer instance if suspended
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    /// Suspends this timer instance if running
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
