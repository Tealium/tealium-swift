//
//  NotificationCenter+AsyncOn.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension NotificationCenter {

    /// Async implementation of `addObserver` that performs the provided block asynchronously on the provided queue,
    /// avoiding blocking the posting thread.
    ///
    /// The standard `NotificationCenter.addObserver` method, instead, blocks the posting thread even when passing the queue parameter.
    func addObserver(forName name: Notification.Name,
                     object obj: Any? = nil,
                     asyncOn queue: DispatchQueue,
                     using block: @escaping @Sendable (Notification) -> Void) -> any NSObjectProtocol {
        addObserver(forName: name, object: obj, queue: nil) { notification in
            queue.async {
                block(notification)
            }
        }
    }
}
