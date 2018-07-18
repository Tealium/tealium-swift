//
//  ViewController.swift
//  ConsentManagerDemo
//
//  Created by Craig Rouse on 15/05/2018.
//  Copyright © 2018 Craig Rouse. All rights reserved.
//

import UIKit
import Eureka

class PreferencesWithSliderViewController: FormViewController {

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

        // MARK: Current Settings
        form +++ Section("Current Settings")
                // MARK: Current Consent Status
                <<< LabelRow { row in
            let consentPrefs = helper.getCurrentConsentPreferences()
            var stat = "Not Consented"
            if let pref = consentPrefs?["tracking_consented"] as? String, pref == "1" {
                stat = "Consented"
            }

            row.title = "Current Status: \(stat)"
            row.tag = "status"
        }.cellUpdate { _, row in
            if let stat = self.form.rowBy(tag: "enable") as? SwitchRow {
                if stat.value != nil {
                    self.currentStatus = (stat.value! == true) ? "Enable Collection": ""
                }
            }
            let stat = self.currentStatus == "Enable Collection" ? "Consented" : "Not Consented"
            row.title = "Current Status: \(stat)"
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

        form +++ Section("Collection Preferences")
        <<< SliderRow() { row in
            if let slideRow = row as SliderRow? {
                slideRow.steps = 3
                slideRow.title = "Consent"
                slideRow.minimumValue = 0
                slideRow.maximumValue = 3
                slideRow.value = detectLevelOfConsent()
                slideRow.tag = "consent-slider"
                slideRow.shouldHideValue = true
            }
        }.cellUpdate { cell, row in
            if let labelRow = self.form.rowBy(tag: "consent-label") as? LabelRow {
                switch row.value {
                case 0.0:
                    labelRow.title = "Not Consented"
                case 1.0:
                    labelRow.title = "Consent Level: Performance"
                case 2.0:
                    labelRow.title = "Consent Level: Marketing"
                case 3.0:
                    labelRow.title = "Consent Level: Personalized Advertising"
                default:
                    labelRow.title = "Not Consented"
                }
                labelRow.updateCell()
            }
        }

        <<< LabelRow() { row in
            row.tag = "consent-label"
            if let statusRow = form.rowBy(tag: "slider") as? SliderRow {
                switch statusRow.value {
                case 0.0:
                    row.title = "Not Consented"
                case 1.0:
                    row.title = "Consent Level: Performance"
                case 2.0:
                    row.title = "Consent Level: Marketing"
                case 3.0:
                    row.title = "Consent Level: Personalized Advertising"
                default:
                    row.title = "Not Consented"
                }
                return
            }
            row.title = "Not Consented"
        }.cellUpdate {cell, row in
            cell.textLabel?.font = .italicSystemFont(ofSize: 14)
        }

        // MARK: Save/Discard
        +++ Section()
        <<< ButtonRow { row in
            row.title = "Save and exit"
        }.onCellSelection { cell, row in
            var settingsDict = [String: Any]()

            let slider = self.form.rowBy(tag: "consent-slider")

            let status: String = {
                switch (slider as? SliderRow)?.value {
                    case 0.0:
                        return "notConsented"
                    case 1.0:
                        return "Performance"
                    case 2.0:
                        return "Marketing"
                    case 3.0:
                        return "Personalized Advertising"
                    default:
                        return "notConsented"
                }
            }()

            settingsDict["consentStatus"] = status == "notConsented" ? status : "consented"

            if status != "notConsented" {
                if let categoriesArray = self.consentGroups[status] {
                    settingsDict["consentCategories"] = categoriesArray
                }
            }

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
        helper.updateConsentPreferences(dict)

    }

    func detectLevelOfConsent() -> Float {
        let helper = TealiumHelper.shared
        let consentPrefs = helper.getCurrentConsentPreferences()
        if let prefCats = consentPrefs?["consent_categories"] as? [String] {
            switch prefCats.count {
                case 15:
                    return 3.0
                case 10:
                    return 2.0
                case 5:
                    return 1.0
                default:
                    return 0
            }
        }
        return 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
