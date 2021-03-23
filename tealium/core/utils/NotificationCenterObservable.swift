//
//  NotificationCenterObservable.swift
//  TealiumCore
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol NotificationCenterObservable: class {
    func post(_ notification: Notification)
    func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol
    func removeObserver(_ observer: Any)
}
 
extension NotificationCenter: NotificationCenterObservable {}
