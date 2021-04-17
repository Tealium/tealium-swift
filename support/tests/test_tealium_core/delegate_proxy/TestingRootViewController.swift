//
//  TestingRootViewController.swift
//  TealiumAppDelegateProxyTests-iOS
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import UIKit

class TestingRootViewController: UIViewController {

    override func loadView() {
        let label = UILabel()
        label.text = "Running Unit Tests..."
        label.textAlignment = .center
        label.textColor = .white

        view = label
    }
}
