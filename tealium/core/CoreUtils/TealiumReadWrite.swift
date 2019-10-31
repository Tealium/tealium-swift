//
//  TealiumReadWrite.swift
//  tealium-swift
//
//  Created by Craig Rouse on 7/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
// credit: https://medium.com/@oyalhi/dispatch-barriers-in-swift-3-6c4a295215d6
// credit: https://swiftexample.info/snippet/read-writeswift_a-voronov_swift

public class ReadWrite {
    private let queueSpecificKey = DispatchSpecificKey<String>()
    private var queueLabel: String
    private let queue: DispatchQueue

    private var isAlreadyInQueue: Bool {
        return DispatchQueue.getSpecific(key: queueSpecificKey) == queueLabel
    }

    public init(_ label: String) {
        queueLabel = label
        queue = DispatchQueue(label: queueLabel, qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .global())
        queue.setSpecific(key: queueSpecificKey, value: queueLabel)
    }

    deinit {
        queue.setSpecific(key: queueSpecificKey, value: nil)
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
        if isAlreadyInQueue {
            work()
        } else {
            queue.async(flags: .barrier, execute: work)
        }
    }

    /// Executes a "write" after a delay￼.
    ///
    /// - Parameters:
    ///     - delay: `DispatchTime`￼
    ///     - work: Closure to be executed after delay
    public func write(after delay: DispatchTime, _ work: @escaping () -> Void) {
        queue.asyncAfter(deadline: delay) {
            self.write(work)
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
