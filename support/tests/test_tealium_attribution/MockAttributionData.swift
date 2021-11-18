//
//  MockAttributionData.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumAttribution
@testable import TealiumCore

class MockAttributionData: AttributionDataProtocol {
    var persistentAttributionData: PersistentAttributionData?
    var appleSearchAdsDataCalled = 0
    var updateConversionValueCalled = 0
    init() {
        self.persistentAttributionData = PersistentAttributionData(withDictionary: [
            TealiumDataKey.adClickedWithin30D: "true",
            TealiumDataKey.adOrgName: "org name",
            TealiumDataKey.adOrgId: "555555",
            TealiumDataKey.adCampaignId: "12345678",
            TealiumDataKey.adCampaignName: "campaign name",
            TealiumDataKey.adConversionDate: "2020-01-04T17:18:07Z",
            TealiumDataKey.adConversionType: "Download",
            TealiumDataKey.adClickedDate: "2020-01-04T17:17:00Z",
            TealiumDataKey.adGroupId: "12345678",
            TealiumDataKey.adGroupName: "adgroup name",
            TealiumDataKey.adRegion: "US",
            TealiumDataKey.adKeyword: "keyword",
            TealiumDataKey.adKeywordMatchType: "Broad",
            TealiumDataKey.adCreativeSetId: "12345678",
            TealiumDataKey.adCreativeSetName: "Creative Set name"
        ])
    }

    var allAttributionData: [String: Any] {
        var allData = persistentAttributionData!.dictionary as [String: Any]
        allData += volatileData
        return allData
    }

    var idfa: String = {
        "IDFA8250-458d-40ed-b150-e0bffeeee849"
    }()

    var idfv: String {
        "IDFV72a0-aef8-47be-9cf5-2628b031d4d9"
    }

    var volatileData: [String: Any] {
        [TealiumDataKey.idfa: idfa,
         TealiumDataKey.idfv: idfv,
         TealiumDataKey.isTrackingAllowed: isAdvertisingTrackingEnabled]
    }

    var isAdvertisingTrackingEnabled: String = "true"

    func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData) -> Void) {
        appleSearchAdsDataCalled += 1
        completion(persistentAttributionData!)
    }

    func updateConversionValue(from dispatch: TealiumRequest) {
        updateConversionValueCalled += 1
    }

}
