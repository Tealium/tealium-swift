//
//  ViewController.swift
//  ConsentManagerDemo
//
//  Copyright © 2018 Tealium. All rights reserved.
//

import Eureka
import UIKit
import Usercentrics
import UsercentricsUI

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
            }.onCellSelection { _, _ in
                TealiumHelper.trackEvent(title: "Button Clicked", dataLayer: ["demo": true])
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
//        UsercentricsCore.reset()
        UsercentricsCore.isReady { [weak self] status in
            guard let self = self else { return }
            UsercentricsCore.shared.getTCFData { data in
                print(data)
            }
            if status.shouldCollectConsent {
//                var usercentricsUI: UIViewController?
                let banner = UsercentricsBanner()
                banner.showFirstLayer(hostView: self, layout: .sheet) { response in
                    self.dismiss(animated: true)
                }
//                usercentricsUI = UsercentricsUserInterface.getPredefinedUI(settings: nil, dismissViewHandler: { response in                    usercentricsUI?.dismiss(animated: true, completion: nil)
//                })
//                guard let ui = usercentricsUI else { return}
//                self.present(ui, animated: true, completion: nil)
            } else {
                let service = status.consents[0]
//                let data = UsercentricsCore.shared.getCMPData()
//                let settings = data.settings
//                let services = data.services
//                let categories = data.categories
                print(service)

                // Apply consent with status.consents
            }
        } onFailure: { error in
            print(error)
            // Handle non-localized error
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
