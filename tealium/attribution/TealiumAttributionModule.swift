//
//  TealiumAttributionModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import AdSupport
import Foundation
import iAd
import UIKit

// MARK: 
// MARK: CONSTANTS
public enum TealiumAttributionKey {
    static let moduleName = "attribution"
    static let isSearchAdsEnabled = "com.tealium.attribution.searchads.enable"
    static let idfa = "device_advertising_id"
    static let idfv = "device_advertising_vendor_id"
    static let isTrackingAllowed = "device_advertising_enabled"
    static let clickedWithin30D = "ad_user_clicked_last_30_days" // True if user clicked on a Search Ads impression within 30 days prior to app download.
    static let clickedDate = "ad_user_date_clicked" // Date and time the user clicked on a corresponding ad
    static let conversionDate = "ad_user_date_converted" // Date and time the user downloaded your app
    static let orgName = "ad_org_name" //The organization that owns the campaign which the corresponding ad was part of.
    static let campaignId = "ad_campaign_id" // The ID of the campaign which the corresponding ad was part of.
    static let campaignName = "ad_campaign_name" // The name of the campaign which the corresponding ad was part of
    static let adGroupId = "ad_group_id" // The ID of the ad group which the corresponding ad was part of
    static let adGroupName = "ad_group_name" // The name of the ad group which the corresponding ad was part of.
    static let adKeyword = "ad_keyword" // The keyword that drove the ad impression which led to the corresponding ad click.
}

private enum AppleInternalKeys {
    static let attribution = "iad-attribution"
    static let clickDate = "iad-click-date"
    static let conversionDate = "iad-conversion-date"
    static let orgName = "iad-org-name"
    static let campaignId = "iad-campaign-id"
    static let campaignName = "iad-campaign-name"
    static let adGroupId = "iad-adgroup-id"
    static let adGroupName = "iad-agroup-name"
    static let keyword = "iad-keyword"
    static let objectVersion = "Version3.1" // peculiarly, Apple keys the entire object from this
}

// MARK: 
// MARK: MODULE SUBCLASS
/**
 Module to automatically add IDFA and IDFV to track calls. Does NOT work with watchOS.
 */
class TealiumAttributionModule: TealiumModule {

    var attributionData = [String: Any]()
    var appleAttributionDetails = [String: Any]()

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAttributionKey.moduleName,
                                   priority: 400,
                                   build: 3,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        if request.config.isSearchAdsEnabled() {
            let loadRequest = TealiumLoadRequest(name: TealiumAttributionModule.moduleConfig().name) { [weak self] _, data, _ in

                // No prior saved data
                guard let loadedData = data else {
                    self?.setNewAttributionData()
                    return
                }

                self?.setLoadedAttributionData(loadedData)
            }
            delegate?.tealiumModuleRequests(module: self,
                                            process: loadRequest)
        } else {
            // set volatile data only
            self.setLoadedAttributionData(nil)
        }

        isEnabled = true
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {

        self.isEnabled = false
        self.attributionData.removeAll()
        self.clearPersistentData()
        self.appleAttributionDetails.removeAll()
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {

        // Add idfa to data - NOTE: This requires additional requirements when
        // submitting to Apple's App Review process, see -
        // https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8

        if self.isEnabled == false {

            // Module disabled - ignore IDFA request

            didFinish(track)
            return
        }

        // Module enabled - add attribution info to data

        var newData = [String: Any]()

        newData += self.attributionData

        newData += track.data

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)

        didFinish(newTrack)

    }

    // setters are mainly reserved for unit tests that need to override internal keys
    func setIdfa(_ idfa: String) {
        self.attributionData[TealiumAttributionKey.idfa] = idfa
    }

    func setAllowed(_ allowed: String) {
        self.attributionData[TealiumAttributionKey.isTrackingAllowed] = allowed
    }

    func isTrackingAllowed() -> Bool {
        let allowed = self.attributionData[TealiumAttributionKey.isTrackingAllowed] as? String ?? "false"
        return Bool(allowed) ?? false
    }

    func getIDFV() -> String? {
        if let idfv = self.attributionData[TealiumAttributionKey.idfv] {
            return idfv as? String
        }
        return nil
    }

    func getIDFA() -> String? {
        if let idfa = self.attributionData[TealiumAttributionKey.idfa] {
            return idfa as? String
        }
        return nil
    }

    func getAllowedState() -> String? {
        if let allowed = self.attributionData[TealiumAttributionKey.isTrackingAllowed] {
            return allowed as? String
        }
        return nil
    }

    // check for IDFA and allowed flag at every launch/init
    func newVolatileData() -> [String: String] {
        var data: [String: String]
        // idfa manually set, e.g. through unit testing module
        if let idfa = self.getIDFA(), let allowed = self.getAllowedState(), let idfv = self.getIDFV() {
            data = [
                TealiumAttributionKey.idfa: idfa,
                TealiumAttributionKey.idfv: idfv,
                TealiumAttributionKey.isTrackingAllowed: allowed
            ]
        } else {
            // not set, so grab new data
            let idManager = ASIdentifierManager.shared()
            // check if user allowed IDFA usage
            // if disabled, returns a dummy string of zeroes
            // TODO: Possibly add deferred check here if nil. Under some circumstances, this could be nil 1st time round
            data = [TealiumAttributionKey.idfa: "unknown",
                    TealiumAttributionKey.isTrackingAllowed: "unknown",
                    TealiumAttributionKey.idfv: "unknown"]
            // guaranteed to be the same for all apps from the same vendor (determined by the 1st 2 parts of the rdns bundle identifier, e.g. com.tealium)
            let idfv = UIDevice.current.identifierForVendor?.uuidString
            #if swift(>=4.0)
            let allowed = idManager.isAdvertisingTrackingEnabled.description
            let idfa = idManager.advertisingIdentifier.uuidString

            data = [TealiumAttributionKey.idfa: idfa,
                TealiumAttributionKey.isTrackingAllowed: allowed]

            #else
            if let idfa = idManager?.advertisingIdentifier.uuidString, let allowed = idManager?.isAdvertisingTrackingEnabled.description {
                data = [TealiumAttributionKey.idfa: idfa,
                        TealiumAttributionKey.isTrackingAllowed: allowed]
            }
            #endif
            if let vendorID = idfv {
                data[TealiumAttributionKey.idfv] = vendorID
            }
        }

        return data
    }

    func savePersistentData(_ data: [String: Any]) {

        let saveRequest = TealiumSaveRequest(name: TealiumAttributionModule.moduleConfig().name,
                                             data: data)

        delegate?.tealiumModuleRequests(module: self,
                                        process: saveRequest)
    }

    func clearPersistentData() {
        let deleteRequest = TealiumDeleteRequest(name: TealiumAttributionModule.moduleConfig().name)
        delegate?.tealiumModuleRequests(module: self, process: deleteRequest)
    }

    func setNewAttributionData() {
        // get attribution details from Apple's servers
        let adClient = ADClient.shared()
        // this is pretty nasty, but Apple Changed the API between Swift 3.2 and Swift 4.0, so not much choice.
        #if swift(>=4.0)
            let completionHander = { (details: [String: NSObject]?, error: Error?) in
            // closure callback
                if let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] {
            if let att = detailsDict[AppleInternalKeys.attribution] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.clickedWithin30D] = att
            }
            if let dat = detailsDict[AppleInternalKeys.clickDate] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.clickedDate] = dat
            }
            if let convDt = detailsDict[AppleInternalKeys.conversionDate] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.conversionDate] = convDt
            }
            if let orgName = detailsDict[AppleInternalKeys.orgName] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.orgName] = orgName
            }
            if let cmpId = detailsDict[AppleInternalKeys.campaignId] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.campaignId] = cmpId
            }
            if let cmpName = detailsDict[AppleInternalKeys.campaignName] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.campaignName] = cmpName
            }
            if let adGrpId = detailsDict[AppleInternalKeys.adGroupId] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.adGroupId] = adGrpId
            }
            if let adGrpName = detailsDict[AppleInternalKeys.adGroupName] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.adGroupName] = adGrpName
            }
            if let keyword = detailsDict[AppleInternalKeys.keyword] as? String {
            self.appleAttributionDetails[TealiumAttributionKey.adKeyword] = keyword
            }

            }
            self.savePersistentData(self.appleAttributionDetails)
            self.setLoadedAttributionData(self.appleAttributionDetails)
            }
            adClient.requestAttributionDetails(completionHander)
        #else
            let completionHander = { (details: [AnyHashable: Any]?, error: Error?) in
                // closure callback
            if let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] {
                    if let att = detailsDict[AppleInternalKeys.attribution] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.clickedWithin30D] = att
                    }
                    if let dat = detailsDict[AppleInternalKeys.clickDate] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.clickedDate] = dat
                    }
                    if let convDt = detailsDict[AppleInternalKeys.conversionDate] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.conversionDate] = convDt
                    }
                    if let orgName = detailsDict[AppleInternalKeys.orgName] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.orgName] = orgName
                    }
                    if let cmpId = detailsDict[AppleInternalKeys.campaignId] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.campaignId] = cmpId
                    }
                    if let cmpName = detailsDict[AppleInternalKeys.campaignName] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.campaignName] = cmpName
                    }
                    if let adGrpId = detailsDict[AppleInternalKeys.adGroupId] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.adGroupId] = adGrpId
                    }
                    if let adGrpName = detailsDict[AppleInternalKeys.adGroupName] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.adGroupName] = adGrpName
                    }
                    if let keyword = detailsDict[AppleInternalKeys.keyword] as? String {
                        self.appleAttributionDetails[TealiumAttributionKey.adKeyword] = keyword
                    }
                }
                self.savePersistentData(self.appleAttributionDetails)
                self.setLoadedAttributionData(self.appleAttributionDetails)
            }
            adClient?.requestAttributionDetails(completionHander)
        #endif

    }

    func setLoadedAttributionData(_ data: [String: Any]?) {
        if let data = data {
            self.attributionData += data
        }

        self.attributionData += self.newVolatileData()
    }

}

public extension TealiumConfig {

    func isSearchAdsEnabled() -> Bool {

        if let enabled = self.optionalData[TealiumAttributionKey.isSearchAdsEnabled] as? Bool {
            return enabled
        }

        // Default
        return false

    }

    func setSearchAdsEnabled(_ enabled: Bool) {
        self.optionalData[TealiumAttributionKey.isSearchAdsEnabled] = enabled
    }

}
