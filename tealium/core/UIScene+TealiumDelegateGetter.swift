//
//  UIScene+TealiumDelegateGetter.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 21/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

private let swizzling: (AnyClass, Selector, Selector) -> Void = { forClass, originalSelector, swizzledSelector in
    guard
        let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
    else { return }
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

@available(iOS 13.0, *)
extension UIScene {
    static let tealSwizzleDelegateGetterOnce: Void = {
        let originalSelector = #selector(getter: delegate)
        let swizzledSelector = #selector(getter: teal_swizzled_delegate)
        swizzling(UIScene.self, originalSelector, swizzledSelector)
    }()

    static var onDelegateGetterBlock: ((UISceneDelegate?) -> Void)?

    // swiftlint:disable identifier_name
    @objc private var teal_swizzled_delegate: UISceneDelegate? {
    // swiftlint:enable identifier_name
        // self.teal_swizzled_delegate would actually be the original implementation (self.delegate) after swizzling
        let delegate = self.teal_swizzled_delegate
        TealiumQueues.secureMainThreadExecution {
            UIScene.onDelegateGetterBlock?(delegate)
        }
        return delegate
    }
}

#endif
