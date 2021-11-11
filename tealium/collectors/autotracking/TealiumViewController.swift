//
// Created by Craig Rouse on 08/02/2021.
// Copyright (c) 2021 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import SwiftUI
import UIKit
#if autotracking
import TealiumCore
#endif

/**
 * Adds a `trackViewControllerAppearence` method that you can call from viewDidAppear to automatically track view appearence.
 */
public protocol TealiumViewControllerTrackable: UIViewController {
}

public extension TealiumViewControllerTrackable {

    /**
     * Call this method on the viewDidAppear method of a viewController if you can't subclass from our TealiumViewController.
     */
    func trackViewControllerAppearence() {
        AutotrackingModule.autoTrackView(viewName: self.viewTitle)
    }
}

/**
 * Subclass this class to allow automatic tracking of viewDidAppear for your ViewController subclass.
 */
open class TealiumViewController: UIViewController, TealiumViewControllerTrackable {
    @objc
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackViewControllerAppearence()
    }
}
#endif
