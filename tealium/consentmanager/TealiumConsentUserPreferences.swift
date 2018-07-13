//
//  TealiumConsentUserPreferences.swift
//  tealium-swift
//
//  Created by Craig Rouse on 25/04/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumConsentUserPreferences {

    var consentCategories: [TealiumConsentCategories]?
    var consentStatus: TealiumConsentStatus?

    public init(consentStatus: TealiumConsentStatus?, consentCategories: [TealiumConsentCategories]?) {
        self.consentCategories = consentCategories
        self.consentStatus = consentStatus != nil ? consentStatus : TealiumConsentStatus.unknown
    }

    public mutating func initWithDictionary(preferencesDictionary: [String: Any]) {
        if let categories = preferencesDictionary[TealiumConsentConstants.consentCategoriesKey] as? [String] {
            self.consentCategories = consentCategoriesStringToEnum(categories)
        }

        if let consentedStatus = preferencesDictionary[TealiumConsentConstants.trackingConsentedKey] as? String {
            switch consentedStatus {
            case TealiumConsentStatus.consented.rawValue:
                self.consentStatus = TealiumConsentStatus.consented
            case TealiumConsentStatus.notConsented.rawValue:
                self.consentStatus = TealiumConsentStatus.notConsented
            default:
                self.consentStatus = TealiumConsentStatus.unknown
            }
        }
    }

    func consentCategoriesStringToEnum(_ categories: [String]) -> [TealiumConsentCategories] {
        var converted = [TealiumConsentCategories]()
        categories.forEach { category in
            if let catEnum = TealiumConsentCategories(rawValue: category) {
                converted.append(catEnum)
            }
        }
        return converted
    }

    func consentCategoriesEnumToStringArray(_ categories: [TealiumConsentCategories]) -> [String] {
        var converted = [String]()
        categories.forEach { category in
            converted.append(category.rawValue)
        }
        return converted
    }

    public func toDictionary() -> [String: Any]? {
        var preferencesDictionary = [String: Any]()

        if let status = self.consentStatus?.rawValue {
            preferencesDictionary[TealiumConsentConstants.trackingConsentedKey] = status
        }

        if let categories = self.consentCategories, categories.count > 0 {
            preferencesDictionary[TealiumConsentConstants.consentCategoriesKey] = consentCategoriesEnumToStringArray(categories)
        } else {
            preferencesDictionary[TealiumConsentConstants.consentCategoriesKey] = [String]()
        }
        return preferencesDictionary.count > 0 ? preferencesDictionary : nil
    }

    public mutating func setConsentStatus(_ status: TealiumConsentStatus) {
        self.consentStatus = status
    }

    public mutating func setConsentCategories(_ categories: [TealiumConsentCategories]) {
        self.consentCategories = categories
    }

    public mutating func resetConsentCategories() {
        self.consentCategories = nil
    }
}
