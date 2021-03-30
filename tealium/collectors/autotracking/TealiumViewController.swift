///
//  TealiumViewController.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TealiumCore

open class TealiumViewController: UIViewController {
    
    var notificationCenter: NotificationCenterObservable = NotificationCenter.default
    
    @objc
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let notification = ViewNotification.forView(self.viewTitle)
        notificationCenter.post(notification)
    }
}
