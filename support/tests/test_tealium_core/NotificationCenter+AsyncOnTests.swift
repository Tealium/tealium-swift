//
//  NotificationCenter+AsyncOnTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

final class NotificationCenterAsyncOnTests: XCTestCase {

    let notificationCenter = NotificationCenter()
    let queue = DispatchQueue(label: "test_queue")

    func test_addObserver_does_not_block_the_posting_thread() {
        let observerClosureCalled = expectation(description: "observer closure is called")
        let name = Notification.Name("test")
        let blocker = DispatchSemaphore(value: 0)
        _ = notificationCenter.addObserver(forName: name, asyncOn: queue) { [queue] _ in
            dispatchPrecondition(condition: .onQueue(queue))
            observerClosureCalled.fulfill()
        }
        // Block the queue before posting. If post blocks on the queue
        // (the normal OperationQueue+waitUntilFinished behaviour in NotificationCenter),
        // it will deadlock here.
        queue.async { blocker.wait() }
        notificationCenter.post(name: name, object: nil)
        // Reaching this line proves post returned without waiting for the queue.
        blocker.signal()
        waitForExpectations(timeout: 1)
    }

}
