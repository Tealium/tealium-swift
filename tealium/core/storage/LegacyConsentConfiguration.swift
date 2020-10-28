//
//  LegacyConsentConfiguration.swift
//  TealiumCore
//
//  Created by Christina S on 10/12/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConsentConfigurable {
    var consentStatus: Int { get set }
    var consentCategories: [String] { get set }
    var enableConsentLogging: Bool { get set }
}

@objc
public class LegacyConsentConfiguration: NSObject, NSSecureCoding, ConsentConfigurable {

    public var consentStatus: Int
    public var consentCategories: [String]
    public var enableConsentLogging: Bool

    public static var supportsSecureCoding: Bool {
        true
    }

    required public init?(coder: NSCoder) {
        self.consentStatus = coder.decodeInteger(forKey: MigrationKey.consentStatus)
        self.enableConsentLogging = coder.decodeBool(forKey: MigrationKey.consentLogging)
        guard let categoriesArray = coder.decodeObject(of: NSArray.self, forKey: MigrationKey.consentCategories),
              let categories = categoriesArray as? [String] else {
            self.consentCategories = TealiumConsentCategories.all.map { $0.rawValue }
            return
        }
        self.consentCategories = categories
    }

    public func encode(with: NSCoder) {
        with.encode(self.consentStatus, forKey: MigrationKey.consentStatus)
        with.encode(self.enableConsentLogging, forKey: MigrationKey.consentLogging)
        with.encode(self.consentCategories, forKey: MigrationKey.consentCategories)
    }

}
