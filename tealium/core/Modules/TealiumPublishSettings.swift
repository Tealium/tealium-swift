//
//  TealiumPublishSettings.swift
//  TealiumCore
//
//  Created by Craig Rouse on 02/12/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

struct RemotePublishSettings: Codable {

    var batterySaver: Bool
    var dispatchExpiration: Int
    var collectEnabled: Bool
    var tagManagementEnabled: Bool
    var batchSize: Int
    var minutesBetweenRefresh: Double
    var dispatchQueueLimit: Int
    var overrideLog: TealiumLogLevel
    var wifiOnlySending: Bool
    var isEnabled: Bool
    var lastFetch: Date
    
    enum CodingKeys: String, CodingKey {
        case v5 = "5"
        case battery_saver
        case dispatch_expiration
        case enable_collect
        case enable_tag_management
        case event_batch_size
        case minutes_between_refresh
        case offline_dispatch_limit
        case override_log
        case wifi_only_sending
        case _is_enabled
        case lastFetch
    }
    
    
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let v5 = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .v5)
            self.batterySaver = try v5.decode(String.self, forKey: .battery_saver) == "true" ? true : false
            self.dispatchExpiration = Int(try v5.decode(String.self, forKey: .dispatch_expiration), radix: 10) ?? TealiumValue.defaultBatchExpirationDays
            self.collectEnabled = try v5.decode(String.self, forKey: .enable_collect) == "true" ? true : false
            self.tagManagementEnabled = try v5.decode(String.self, forKey: .enable_tag_management) == "true" ? true : false
            self.batchSize = Int(try v5.decode(String.self, forKey: .event_batch_size), radix: 10) ?? 1
            self.minutesBetweenRefresh = Double(try v5.decode(String.self, forKey: .minutes_between_refresh)) ?? 15.0
            self.dispatchQueueLimit = Int(try v5.decode(String.self, forKey: .offline_dispatch_limit), radix: 10) ?? TealiumValue.defaultMaxQueueSize
            let logLevel = try v5.decode(String.self, forKey: .override_log)
            
            switch logLevel {
            case "dev":
                self.overrideLog = .verbose
            case "qa":
                self.overrideLog = .warnings
            case "prod":
                self.overrideLog = .errors
            default:
                self.overrideLog = .none
            }
            
            self.wifiOnlySending = try v5.decode(String.self, forKey: .wifi_only_sending) == "true" ? true : false
            self.isEnabled = try v5.decode(String.self, forKey: ._is_enabled) == "true" ? true : false
            self.lastFetch = Date()
        } catch {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.batterySaver = try values.decode(Bool.self, forKey: .battery_saver)
            self.dispatchExpiration = try values.decode(Int.self, forKey: .dispatch_expiration)
            self.collectEnabled = try values.decode(Bool.self, forKey: .enable_collect)
            self.tagManagementEnabled = try values.decode(Bool.self, forKey: .enable_tag_management)
            self.batchSize = try values.decode(Int.self, forKey: .event_batch_size)
            self.minutesBetweenRefresh = try values.decode(Double.self, forKey: .minutes_between_refresh)
            self.dispatchQueueLimit = try values.decode(Int.self, forKey: .offline_dispatch_limit)
            let logLevel = try values.decode(String.self, forKey: .override_log)
            
            self.overrideLog = TealiumLogLevel.fromString(logLevel)
            
            self.wifiOnlySending = try values.decode(Bool.self, forKey: .wifi_only_sending)
            self.isEnabled = try values.decode(Bool.self, forKey: ._is_enabled)
            self.lastFetch = (try? values.decode(Date.self, forKey: .lastFetch)) ?? Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(batterySaver, forKey: .battery_saver)
        try container.encode(dispatchExpiration, forKey: .dispatch_expiration)
        try container.encode(collectEnabled, forKey: .enable_collect)
        try container.encode(tagManagementEnabled, forKey: .enable_tag_management)
        try container.encode(batchSize, forKey: .event_batch_size)
        try container.encode(minutesBetweenRefresh, forKey: .minutes_between_refresh)
        try container.encode(dispatchQueueLimit, forKey: .offline_dispatch_limit)
        try container.encode(overrideLog.description, forKey: .override_log)
        try container.encode(wifiOnlySending, forKey: .wifi_only_sending)
        try container.encode(isEnabled, forKey: ._is_enabled)
        try container.encode(lastFetch, forKey: .lastFetch)
    }
    
    public func newConfig(with config: TealiumConfig) -> TealiumConfig {
        let config = config.copy
        config.batterySaverEnabled = batterySaver
        config.dispatchExpiration = config.dispatchExpiration ?? dispatchExpiration
        config.batchingEnabled = config.batchingEnabled ?? (batchSize > 1)
        config.batchSize = (config.batchSize != TealiumValue.maxEventBatchSize) ? config.batchSize : batchSize
        config.dispatchQueueLimit = config.dispatchQueueLimit ?? dispatchQueueLimit
        config.wifiOnlySending = config.wifiOnlySending ?? self.wifiOnlySending
        config.minutesBetweenRefresh = config.minutesBetweenRefresh ?? minutesBetweenRefresh
        config.isEnabled = config.isEnabled ?? isEnabled

        if let existingModulesList = config.modulesList {
         
            let isWhiteList = existingModulesList.isWhitelist,
            moduleNames = existingModulesList.moduleNames
            
            
            var newModuleNames = moduleNames
            if isWhiteList {
                if moduleNames.contains(TealiumKey.tagManagementModuleName), !self.tagManagementEnabled {
                    newModuleNames.remove(TealiumKey.tagManagementModuleName)
                } else if !moduleNames.contains(TealiumKey.tagManagementModuleName), self.tagManagementEnabled {
                    newModuleNames.insert(TealiumKey.tagManagementModuleName)
                }
                if moduleNames.contains(TealiumKey.collectModuleName), !self.collectEnabled {
                    newModuleNames.remove(TealiumKey.collectModuleName)
                } else if !moduleNames.contains(TealiumKey.collectModuleName), self.collectEnabled {
                    newModuleNames.insert(TealiumKey.collectModuleName)
                }
            } else {
                if moduleNames.contains(TealiumKey.tagManagementModuleName), self.tagManagementEnabled {
                    newModuleNames.remove(TealiumKey.tagManagementModuleName)
                } else if !moduleNames.contains(TealiumKey.tagManagementModuleName), !self.tagManagementEnabled {
                    newModuleNames.insert(TealiumKey.tagManagementModuleName)
                }
                if moduleNames.contains(TealiumKey.collectModuleName), self.collectEnabled {
                    newModuleNames.remove(TealiumKey.collectModuleName)
                } else if !moduleNames.contains(TealiumKey.collectModuleName), !self.collectEnabled {
                    newModuleNames.insert(TealiumKey.collectModuleName)
                }
            }

            config.modulesList = TealiumModulesList(isWhitelist: isWhiteList, moduleNames: newModuleNames)
            
        } else {
            var newModuleNames = Set<String>()
            
            if !self.tagManagementEnabled {
                newModuleNames.insert(TealiumKey.tagManagementModuleName)
            }
           
            if !self.collectEnabled {
               newModuleNames.insert(TealiumKey.collectModuleName)
            }
            
            config.modulesList = TealiumModulesList(isWhitelist: false, moduleNames: newModuleNames)
        }
        
        let overrideLog = config.logLevel
        config.logLevel = (overrideLog ?? self.overrideLog)

        return config
    }
}

