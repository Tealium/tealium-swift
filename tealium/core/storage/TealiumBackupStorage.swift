//
//  TealiumBackupStorage.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumBackupStorage {
    public let userDefaults: UserDefaults?
    var domainName: String
    init(account: String, profile: String) {
        let domainName = "com.swift.tealium.\(account).\(profile).backup"
        self.domainName = domainName
        userDefaults = UserDefaults(suiteName: domainName)
    }
    public var visitorId: String? {
        get {
            userDefaults?.string(forKey: TealiumBacupKey.visitorId)
        }
        set {
            userDefaults?.set(newValue, forKey: TealiumBacupKey.visitorId)
        }
    }
    public var appId: String? {
        get {
            userDefaults?.string(forKey: TealiumBacupKey.appId)
        }
        set {
            userDefaults?.set(newValue, forKey: TealiumBacupKey.appId)
        }
    }
    func clear() {
        userDefaults?.removePersistentDomain(forName: domainName)
    }
}

public enum TealiumBacupKey {
    static let visitorId = "visitor_id"
    static let appId = "app_id"
}
