//
//  ViewController.swift
//  ConsentManagerDemo
//
//  Created by Craig Rouse on 15/05/2018.
//  Copyright © 2018 Craig Rouse. All rights reserved.
//

import UIKit
import Eureka

class PreferencesOnOffViewController: FormViewController {

    var lastLoadFromCategories = false
    var lastLoadFromMaster = false
    var currentStatus = ""
    let consentGroups = ["Off" : [],
        "Performance": ["analytics", "monitoring", "big_data", "mobile", "crm"],
        "Marketing": ["analytics", "monitoring", "big_data", "mobile", "crm", "affiliates", "email", "search", "engagement", "cdp"],
        "Personalized Advertising": ["analytics", "monitoring", "big_data", "mobile", "crm", "affiliates", "email", "search", "engagement", "cdp", "display_ads", "personalization", "social", "cookiematch", "misc"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        let helper = TealiumHelper.shared
        let consentPrefs = helper.getCurrentConsentPreferences()
        let initialStatus: Bool = {
            if let pref = consentPrefs?["tracking_consented"] as? String {
                return pref == "consented" ? true : false
            }
            return false
        }()

        // MARK: Current Settings
        form +++ Section("Current Settings")
                // MARK: Current Consent Status
        <<< LabelRow { row in
            let consentPrefs = helper.getCurrentConsentPreferences()
            var stat = "Not Consented"
            if let pref = consentPrefs?["tracking_consented"] as? String, pref == "consented" {
                stat = "Consented"
            }

            row.title = "Current Status: \(stat)"
            row.tag = "status"
        }

        // MARK: Current Consent Categories
        <<< LabelRow { row in
            let consentPrefs = helper.getCurrentConsentPreferences()
            var cats = ""
            if let prefCats = consentPrefs?["consent_categories"] as? [String] {
                cats = prefCats.joined(separator: ", ")
            }

            cats = cats == "" ? "None" : cats
            row.title = "Current Categories: \(cats)"
            row.tag = "statuscats"
            row.cell.textLabel?.numberOfLines = 5
        }.cellUpdate { _, row in
            let consentPrefs = helper.getCurrentConsentPreferences()
            var cats = ""
            if let prefCats = consentPrefs?["consent_categories"] as? [String] {
                cats = prefCats.joined(separator: ", ")
            }

            row.title = "Current Categories: \(cats)"
            row.tag = "statuscats"
        }

        // MARK: Consent On/Off Selection
        form +++ Section("Data Collection Settings")
        <<< SwitchRow() { row in
            row.title = "Consent Status"
            row.tag = "enable"
            row.value = initialStatus
        }.onChange { row in
            let sect = self.form.sectionBy(tag: "Preferences")
            if let sec = sect, self.lastLoadFromCategories == false {
                for switchrow in sec {
                    if let r = switchrow as? SwitchRow {
                        self.lastLoadFromMaster = true
                        r.value = row.value ?? false
                        r.updateCell()
                        self.lastLoadFromMaster = false
                    }
                }
            }
            let statusUpdate = self.form.rowBy(tag: "status")
            statusUpdate?.updateCell()
        }

        // MARK: Save/Discard
        +++ Section()
        <<< ButtonRow { row in
            row.title = "Save and exit"
        }.onCellSelection { cell, row in
            var settingsDict = [String: Any]()

            let onOff = self.form.rowBy(tag: "enable") as? SwitchRow

            let status = onOff?.value ?? false

            settingsDict["consentStatus"] = status ? "consented" : "notConsented"

            self.savePreferences(settingsDict)
            self.dismiss(animated: true)
        }

        // MARK: Discard changes and exit
        <<< ButtonRow { row in
            row.title = "Discard Changes"
        }.onCellSelection({_,_ in
            self.dismiss(animated: true)
        })
    }

    func savePreferences(_ dict: [String:Any]) {
        let helper = TealiumHelper.shared
        helper.simpleConsent(dict)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
