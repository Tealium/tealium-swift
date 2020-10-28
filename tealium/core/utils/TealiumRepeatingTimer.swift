//
//  TealiumRepeatingTimer.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

// Credit/source: https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9 🙏

import Foundation

/// Safe implementation of a repeating timer for scheduling connectivity checks
public class TealiumRepeatingTimer {

    let timeInterval: TimeInterval
    let dispatchQueue: DispatchQueue
    let readWriteQueue = TealiumQueues.backgroundConcurrentQueue

    /// - Parameters:
    ///     - timeInterval: TimeInterval between runs of the timed event￼
    ///     - dispatchQueue: The queue to use for the timer
    public init(timeInterval: TimeInterval, dispatchQueue: DispatchQueue = TealiumQueues.backgroundSerialQueue) {
        self.timeInterval = timeInterval
        self.dispatchQueue = dispatchQueue
    }

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: dispatchQueue)

        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timer
    }()

    public var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        self.timer.setEventHandler {}
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        if self.state == .suspended {
            self.timer.resume()
        }
        self.timer.cancel()
    }

    /// Resumes this timer instance if suspended
    public func resume() {
        readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            if self.state == .resumed {
                return
            }
            self.state = .resumed
            self.timer.resume()
        }
    }

    /// Suspends this timer instance if running
    public func suspend() {
        readWriteQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            if self.state == .suspended {
                return
            }
            self.state = .suspended
            self.timer.suspend()
        }
    }
}
