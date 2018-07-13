//
//  ViewController.swift
//  ConsentManagerDemo
//
//  Created by Craig Rouse on 15/05/2018.
//  Copyright © 2018 Craig Rouse. All rights reserved.
//

import UIKit
import Eureka

class PreferencesDialogViewController: FormViewController {

    var lastLoadFromCategories = false
    var lastLoadFromMaster = false
    var currentStatus = ""

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
        let initialCats: [String] = {
            if let cats = consentPrefs?["consent_categories"] as? [String] {
                return cats
            }
            return [String]()
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
        <<< LabelRow { row in
            row.title = "We would like to collect data about your app experience to help us improve our products. Please choose your preferences here."
            row.cell.textLabel?.numberOfLines = 3
        }.cellUpdate { cell, row in
            cell.textLabel?.font = .italicSystemFont(ofSize: 14.0)
            cell.backgroundColor = UIColor(red:0.95, green:0.94, blue:1.00, alpha:1.0)
        }

        // MARK: Category Preferences
        +++ Section("Preferences") { section in
            section.tag = "Preferences"
        }

        // MARK: Save/Discard
        +++ Section()
        <<< ButtonRow { row in
            row.title = "Save and exit"
        }.onCellSelection { cell, row in
            var settingsDict = [String: Any]()
            var categoriesArray = [String]()
            if let enabled = self.form.rowBy(tag: "enable") as? SwitchRow {
                if let val = enabled.value {
                    settingsDict["consentStatus"] = val ? "consented" : "notConsented"
                }
            }
            let sect = self.form.sectionBy(tag: "Preferences")
            if let sec = sect {
                for switchrow in sec {
                    if let r = switchrow as? SwitchRow {
                        if let title = r.tag, r.value == true {
                            categoriesArray.append(title)
                        }
                    }
                }
            }
            settingsDict["consentCategories"] = categoriesArray
            self.savePreferences(settingsDict)
            self.dismiss(animated: true)
        }

        // MARK: Discard changes and exit
        <<< ButtonRow { row in
            row.title = "Discard Changes"
        }.onCellSelection({_,_ in
            self.dismiss(animated: true)
        })

        // Customize your categories
        let consentCategories = [
            ["name": "Analytics", "tealiumName": "analytics", "desc": "Help us improve your experience"],
            ["name": "Affiliates", "tealiumName": "affiliates", "desc": "Earn credit for shopping with us"],
            ["name": "Display Ads", "tealiumName": "display_ads", "desc": "Help us improve the ads you see"],
            ["name": "Email", "tealiumName": "email", "desc": "Allows email marketing tools"],
            ["name": "Personalization", "tealiumName": "personalization", "desc": "Let us tailor your app experience"],
            ["name": "Search", "tealiumName": "search", "desc": "Helps optimize search results"],
            ["name": "Social", "tealiumName": "social", "desc": "Social media advertising"],
            ["name": "Big Data", "tealiumName": "big_data", "desc": "Helps us better understand our customers"],
            ["name": "Mobile", "tealiumName": "mobile", "desc": "Optimizes your mobile experience"],
            ["name": "Engagement", "tealiumName": "engagement", "desc": "Keep in touch with us"],
            ["name": "Monitoring", "tealiumName": "monitoring", "desc": "Lets us know when things are broken"],
            ["name": "CDP", "tealiumName": "cdp", "desc": "Helps us understand your individual needs"],
            ["name": "CRM", "tealiumName": "crm", "desc": "Helps us keep track of your purchase history"],
            ["name": "Cookie Match", "tealiumName": "cookiematch", "desc": "Required for personalized ads"],
            ["name": "Misc", "tealiumName": "misc", "desc": "Everything else"]
        ]

        // MARK: Populate categories
        let sect = form.sectionBy(tag: "Preferences")
        for cat in consentCategories {
            if let sec = sect, let name = cat["name"], let tealiumName = cat["tealiumName"], let desc = cat["desc"] {
                sec <<< SwitchRow() { row in
                    row.title = "\(name)"
                    row.tag = tealiumName
                    if let tag = row.tag, initialCats.contains(tag) {
                        row.value = true
                    }
                }.onChange { row in
                    if self.lastLoadFromMaster == true {
                        return
                    }
                    if let enableRow = self.form.rowBy(tag: "enable") as? SwitchRow {
                        if enableRow.value == false || enableRow.value == nil {
                            self.lastLoadFromCategories = true
                            enableRow.value = true
                            enableRow.updateCell()
                            self.lastLoadFromCategories = false
                        }
                        let sect = self.form.sectionBy(tag: "Preferences")
                        if let sec = sect {
                            for switchrow in sec {
                                if let r = switchrow as? SwitchRow {
                                    if r.value == true {
                                        return
                                    }
                                }
                            }
                            self.lastLoadFromCategories = true
                            enableRow.value = false
                            enableRow.updateCell()
                            self.lastLoadFromCategories = false
                        }
                    }
                }
                sec <<< LabelRow() { row in
                    row.cell.backgroundColor = UIColor(red:0.95, green:0.94, blue:1.00, alpha:1.0)
                    row.title = desc
                }.cellUpdate { cell, row in
                    cell.textLabel?.font = .italicSystemFont(ofSize: 14.0)
                }
            }
        }
    }

    func savePreferences(_ dict: [String:Any]) {
        let helper = TealiumHelper.shared
        helper.updateConsentPreferences(dict)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
