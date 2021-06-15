//
//  CustomAlert.swift
//
//  Created by Christina on 4/2/21.
//  Copyright © 2021 Tealium. All rights reserved.
//

#if os(iOS)
import SwiftUI

public struct TealiumAlertOptions {
    var title: String
    var titleColor: UIColor
    var alertBackgroundColor: UIColor
    var textFieldBackgroundColor: UIColor
    var textFieldPlaceholderTextColor: UIColor
    var textFieldPlaceholderText: String
    var cancelActionTitle: String
    var confirmActionTitle: String
    var buttonTextColor: UIColor
    var confirmActionHandler: ((UIAlertAction) -> Void)?
    
    public init(title: String,
                titleColor: UIColor,
                alertBackgroundColor: UIColor,
                textFieldBackgroundColor: UIColor,
                textFieldPlaceholderTextColor: UIColor,
                textFieldPlaceholderText: String,
                cancelActionTitle: String,
                confirmActionTitle: String,
                buttonTextColor: UIColor,
                confirmActionHandler: ((UIAlertAction) -> Void)?) {
        self.title = title
        self.titleColor = titleColor
        self.alertBackgroundColor = alertBackgroundColor
        self.textFieldBackgroundColor = textFieldBackgroundColor
        self.textFieldPlaceholderTextColor = textFieldPlaceholderTextColor
        self.textFieldPlaceholderText = textFieldPlaceholderText
        self.cancelActionTitle = cancelActionTitle
        self.confirmActionTitle = confirmActionTitle
        self.buttonTextColor = buttonTextColor
        self.confirmActionHandler = confirmActionHandler
    }
    
}

// Workaround until SwiftUI adds text fields to alerts 🤞
public func customAlert(options: TealiumAlertOptions, completion: @escaping (String) -> Void) {
    let attributedTitle = NSAttributedString(string: options.title, attributes: [
        NSAttributedString.Key.foregroundColor : options.titleColor
    ])
    let alert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
    alert.view.tintColor = options.buttonTextColor
    alert.setValue(attributedTitle, forKey: "attributedTitle")
    alert.addTextField() { textField in
        textField.superview?.backgroundColor = options.textFieldBackgroundColor
        textField.superview?.superview?.subviews[0].removeFromSuperview()
        textField.attributedPlaceholder = NSAttributedString(string: options.textFieldPlaceholderText,
                                                             attributes: [NSAttributedString.Key.foregroundColor: options.textFieldPlaceholderTextColor,
                                                                          NSAttributedString.Key.backgroundColor: options.textFieldBackgroundColor])
    }
    alert.addAction(UIAlertAction(title: options.cancelActionTitle, style: .cancel) { _ in })
    alert.addAction(UIAlertAction(title: options.confirmActionTitle, style: .default, handler: options.confirmActionHandler))
    showAlert(alert: alert, with: options)
}

private func showAlert(alert: UIAlertController, with options: TealiumAlertOptions) {
    if let controller = topMostViewController() {
        controller.present(alert, animated: true)
        let subview = (alert.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
        subview.layer.cornerRadius = 10
        subview.backgroundColor = options.alertBackgroundColor
    }
}

private func keyWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
    .filter {$0.activationState == .foregroundActive}
    .compactMap {$0 as? UIWindowScene}
    .first?.windows.filter {$0.isKeyWindow}.first
}

private func topMostViewController() -> UIViewController? {
    guard let rootController = keyWindow()?.rootViewController else {
        return nil
    }
    return topMostViewController(for: rootController)
}

private func topMostViewController(for controller: UIViewController) -> UIViewController {
    if let presentedController = controller.presentedViewController {
        return topMostViewController(for: presentedController)
    } else if let navigationController = controller as? UINavigationController {
        guard let topController = navigationController.topViewController else {
            return navigationController
        }
        return topMostViewController(for: topController)
    } else if let tabController = controller as? UITabBarController {
        guard let topController = tabController.selectedViewController else {
            return tabController
        }
        return topMostViewController(for: topController)
    }
    return controller
}
#endif
