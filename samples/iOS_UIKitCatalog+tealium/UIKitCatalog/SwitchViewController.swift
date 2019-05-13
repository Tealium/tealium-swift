/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UISwitch.
*/

import UIKit

class SwitchViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultSwitch: UISwitch!
    
    @IBOutlet weak var tintedSwitch: UISwitch!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSwitch()
        configureTintedSwitch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TealiumHelper.shared.trackView(title: self.title ?? "View Controller", data: nil)
        super.viewDidAppear(animated)
    }

    // MARK: - Configuration

    func configureDefaultSwitch() {
        defaultSwitch.setOn(true, animated: false)

        defaultSwitch.addTarget(self, action: #selector(SwitchViewController.switchValueDidChange(_:)), for: .valueChanged)
    }

    func configureTintedSwitch() {
        tintedSwitch.tintColor = UIColor.applicationBlueColor
        tintedSwitch.onTintColor = UIColor.applicationGreenColor
        tintedSwitch.thumbTintColor = UIColor.applicationPurpleColor

        tintedSwitch.addTarget(self, action: #selector(SwitchViewController.switchValueDidChange(_:)), for: .valueChanged)
    }

    // MARK: - Actions

    @objc func switchValueDidChange(_ aSwitch: UISwitch) {
        NSLog("A switch changed its value: \(aSwitch).")
    }
}
