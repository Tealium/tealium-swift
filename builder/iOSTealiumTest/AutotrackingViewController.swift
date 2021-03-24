// 
// AutotrackingViewController.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TealiumCore
import TealiumAutotracking

struct ViewControllerWrapper: View, UIViewControllerRepresentable {
    typealias UIViewControllerType = AutotrackingViewController
    
    func makeUIViewController(context: Context) -> AutotrackingViewController {
        let controller = AutotrackingViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AutotrackingViewController, context: Context) { }
}

class AutotrackingViewController: TealiumViewController {
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .tealBlue
        label.text = """
                    This view was autotracked by using the UIViewController subclass
                    TealiumViewController.

                    The dataLayer should contain:
                    {screen_title: \"Autotracking\"}
                    """
        return label
    }()
    
    
    var _title: String? // To set a custom screen_title, set this property
    
    override var title: String? {
        get {
            _title
        }
        set {
            _title = newValue
        }
    }

    @objc
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    
    func setupUI() {
        view.addSubview(label)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: label.topAnchor),
            view.bottomAnchor.constraint(equalTo: label.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: label.trailingAnchor)
        ])
    }

}

extension UIColor {
    static let tealBlue = UIColor(red: 0.0, green: 0.49, blue: 0.76, alpha: 1.0)
}
