//
// Created by Craig Rouse on 08/02/2021.
// Copyright (c) 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TealiumCore

internal struct ViewNotification {
    private init() {}
    static func forView(_ viewName: String) -> Notification {
        return Notification(name: Notification.Name(rawValue: "com.tealium.autotracking.view"), userInfo: ["view_name": viewName])
    }
}


open class TealiumViewController: UIViewController { 
    @objc
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let notification = ViewNotification.forView(self.viewTitle)
        NotificationCenter.default.post(notification)
    }
}

extension UIViewController {
    var viewTitle: String {
        return self.title ?? String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    }
}
