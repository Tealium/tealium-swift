//
//  TealiumAttributionConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 14/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumAttributionKey: CaseIterable {
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

public enum AppleInternalKeys {
    static let attribution = "iad-attribution"
    static let clickDate = "iad-click-date"
    static let conversionDate = "iad-conversion-date"
    static let orgName = "iad-org-name"
    static let campaignId = "iad-campaign-id"
    static let campaignName = "iad-campaign-name"
    static let adGroupId = "iad-adgroup-id"
    static let adGroupName = "iad-adgroup-name"
    static let keyword = "iad-keyword"
    static let objectVersion = "Version3.1" // This is the root key for the returned data
}
