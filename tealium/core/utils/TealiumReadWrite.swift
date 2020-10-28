//
//  TealiumReadWrite.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
// credit: https://medium.com/@oyalhi/dispatch-barriers-in-swift-3-6c4a295215d6
// credit: https://swiftexample.info/snippet/read-writeswift_a-voronov_swift

public class ReadWrite {
    private let queueSpecificKey = DispatchSpecificKey<String>()
    private let barrierSpecificKey = DispatchSpecificKey<Bool>()
    private let specificValue: String
    private let queue: DispatchQueue

    private var isAlreadyInQueue: Bool {
        return DispatchQueue.getSpecific(key: queueSpecificKey) == specificValue
    }

    private var isAlreadyBarriered: Bool {
        return DispatchQueue.getSpecific(key: barrierSpecificKey) == true
    }

    public init(_ label: String) {
        specificValue = label
        queue = DispatchQueue(label: label, qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .global())
        queue.setSpecific(key: queueSpecificKey, value: specificValue)
        queue.setSpecific(key: barrierSpecificKey, value: false)
    }

    deinit {
        queue.setSpecific(key: queueSpecificKey, value: nil)
        queue.setSpecific(key: barrierSpecificKey, value: nil)
    }

    // Solving readers-writers problem: any amount of readers can access data at a time, but only one writer is allowed at a time
    // - reads are executed concurrently on the executing queue, but are executed synchronously on a calling queue
    // - write blocks executing queue, but is executed asynchronously on a calling queue so it doesn't have to wait
    // note:
    //  it's fine to have async write, and sync reads, because write blocks queue and reads are executed synchronously;
    //  so if we want to read after writing, we'll still be waiting (reads are sync) for write to finish and allow reads to execute;

    /// Supports "write" type operations￼.
    ///
    /// - Parameter work: Closure to be executed.
    public func write(_ work: @escaping () -> Void) {
        if isAlreadyBarriered {
            work()
        } else {
            queue.async(flags: .barrier, execute: barrieredWork(work))
        }
    }

    /// Executes a "write" after a delay￼.
    ///
    /// - Parameters:
    ///     - delay: `DispatchTime`￼
    ///     - work: Closure to be executed after delay
    public func write(after delay: DispatchTime, _ work: @escaping () -> Void) {
        queue.asyncAfter(deadline: delay, flags: .barrier, execute: barrieredWork(work))
    }

    /// Executes the closure while also setting the barrier flag up for other future, nested, barriered work
    ///
    /// This method's returned block should be passed inside every barriered execution on the queue.
    ///
    /// - Parameter work: Closure to be executed in between the barrierKey set
    /// - Returns: A block that must be passed to the async (barriered) method of the queue
    private func barrieredWork(_ work: @escaping () -> Void) -> (() -> Void) {
        return { [weak self] in
            guard let self = self else {
                return
            }
            self.queue.setSpecific(key: self.barrierSpecificKey, value: true)
            work()
            self.queue.setSpecific(key: self.barrierSpecificKey, value: false)
        }
    }

    // If we're already executing inside queue, then no need to add task there synchronosuly since it can lead to a deadlock.
    // Result is discardable, in case the block has Void return type.
    @discardableResult
    public func read<T>(_  work: () throws -> T) rethrows -> T {
        if isAlreadyInQueue {
            return try work()
        } else {
            return try queue.sync(execute: work)
        }
    }
}
