//
//  ViewController.swift
//  ConsentManagerDemo
//
//  Created by Craig Rouse on 15/05/2018.
//  Copyright © 2018 Craig Rouse. All rights reserved.
//

import UIKit
import Eureka

class ViewController: FormViewController {

    override func viewDidLoad() {
    super.viewDidLoad()
        let helper = TealiumHelper.shared
        // MARK: Demo Tracking Call
        form +++ Section("Demo Tracking Call")
            <<< LabelRow { row in
                row.title = "Triggers a Tealium tracking call"
                row.cell.textLabel?.numberOfLines = 3
            }

            <<< ButtonRow { row in
                row.title = "Trigger"
            }.onCellSelection { _,_ in
                helper.track(title: "Button Clicked", data: ["demo" : true])
            }

            // MARK: Preferences Button
            +++ Section("Preferences") { section in
                section.tag = "Preferences"
            }
            <<< ButtonRow { row in
                row.title = "Preferences List View"
            }.onCellSelection { _, _ in
                 self.present(PreferencesDialogViewController(), animated: true)
            }
            <<< ButtonRow { row in
                row.title = "Preferences Slider View"
            }.onCellSelection { _, _ in
                self.present(PreferencesWithSliderViewController(), animated: true)
            }
            <<< ButtonRow { row in
                row.title = "Simple Preferences View"
            }.onCellSelection { _, _ in
                self.present(PreferencesOnOffViewController(), animated: true)
            }
            <<< ButtonRow { row in
                row.title = "Reset Preferences"
            }.onCellSelection { _, _ in
                helper.resetConsentPreferences()
            }
    }

    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
    }

}
