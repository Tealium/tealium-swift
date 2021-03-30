// 
// AutotrackingUtils.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if autotracking
import TealiumCore
#endif

final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenterObservable
    let token: Any

    init(notificationCenter: NotificationCenterObservable = NotificationCenter.default,
         token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }

    deinit {
        notificationCenter.removeObserver(token)
    }
}

struct ViewNotification {
    private init() {}
    static func forView(_ viewName: String) -> Notification {
        return Notification(name: Notification.Name(rawValue: TealiumAutotrackingValue.viewNotificationName), userInfo: [TealiumAutotrackingKey.viewName: viewName])
    }
}


extension UIViewController {
    var viewTitle: String {
        return self.title ?? String(describing: type(of: self)).replacingOccurrences(of: TealiumAutotrackingValue.viewControllerClassPrefix, with: "")
    }
}
