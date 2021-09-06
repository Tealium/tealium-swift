//
// Created by Craig Rouse on 08/02/2021.
// Copyright (c) 2021 Tealium, Inc. All rights reserved.
//


#if os(iOS)
import Foundation
import UIKit
import SwiftUI
import TealiumCore

open class TealiumViewController: UIViewController { 
    @objc
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TealiumInstanceManager.shared.autoTrackView(viewName: self.viewTitle)
    }
}
#endif
