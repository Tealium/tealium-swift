// 
// UIViewController+Tealium.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#if os(iOS)
#if autotracking
import TealiumCore
#endif

import Foundation
import UIKit

private let swizzling: (AnyClass, Selector, Selector) -> Void = { forClass, originalSelector, swizzledSelector in
    guard
        let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
    else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

@objc extension UIViewController {

    var viewTitle: String {
        return self.title ?? String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    }

    private typealias ViewDidAppear = @convention(c) (Bool) -> Void

    private static let cls: AnyClass = UIViewController.self

    fileprivate static var isAutotrackingEnabled: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "TealiumAutotrackingViewControllersEnabled") as? Bool ?? true
    }

    public static func setUp() {
        TealiumQueues.secureMainThreadExecution {
            _ = runOnce
        }
    }

    @nonobjc private static let runOnce: () = {
        guard isAutotrackingEnabled else {
            return
        }
        let originalMethodSelector = #selector(viewDidAppear(_:))
        let newMethodSelector = #selector(tealiumViewDidAppear(_:))
        swizzling(cls, originalMethodSelector, newMethodSelector)
    }()

    dynamic func tealiumViewDidAppear(_ animated: Bool) {
        defer {
            self.tealiumViewDidAppear(animated) // calls the basic method
        }
        // Avoid double-tracking if this is a TealiumViewController already
        if self is TealiumViewController {
            return
        }

        let cls = String(reflecting: type(of: self))
        switch cls {
        // swiftlint:disable identifier_name
        case let x where x.contains("SwiftUI."):
                break
        case let x where x.contains("UIInputWindowController"):
                break
        // swiftlint:enable identifier_name
        default:
            AutotrackingModule.autoTrackView(viewName: viewTitle)
        }
    }

}
#endif
