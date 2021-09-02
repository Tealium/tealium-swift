// 
// AutotrackingUtils.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit


final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any

    init(notificationCenter: NotificationCenter = .default, token: Any) {
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
        return Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.view"), userInfo: ["view_name": viewName])
    }
}


extension UIViewController {
    var viewTitle: String {
        return self.title ?? String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    }
}
