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
    var appleAttributionDetails: PersistentAttributionData?
    var appleSearchAdsDataCalled = 0
    var updateConversionValueCalled = 0
    init() {
        self.appleAttributionDetails = PersistentAttributionData(withDictionary: [
            AttributionKey.clickedWithin30D: "true",
            AttributionKey.orgName: "org name",
            AttributionKey.orgId: "555555",
            AttributionKey.campaignId: "12345678",
            AttributionKey.campaignName: "campaign name",
            AttributionKey.conversionDate: "2020-01-04T17:18:07Z",
            AttributionKey.conversionType: "Download",
            AttributionKey.clickedDate: "2020-01-04T17:17:00Z",
            AttributionKey.adGroupId: "12345678",
            AttributionKey.adGroupName: "adgroup name",
            AttributionKey.region: "US",
            AttributionKey.adKeyword: "keyword",
            AttributionKey.adKeywordMatchType: "Broad",
            AttributionKey.creativeSetId: "12345678",
            AttributionKey.creativeSetName: "Creative Set name"
        ])
    }

    var allAttributionData: [String: Any] {
        var allData = appleAttributionDetails!.dictionary as [String: Any]
        allData += volatileData
        return allData
    }

    var idfa: String {
        "IDFA8250-458d-40ed-b150-e0bffeeee849"
    }

    var idfv: String {
        "IDFV72a0-aef8-47be-9cf5-2628b031d4d9"
    }

    var volatileData: [String: Any] {
        [AttributionKey.idfa: idfa,
         AttributionKey.idfv: idfv,
         AttributionKey.isTrackingAllowed: isAdvertisingTrackingEnabled]
    }

    var isAdvertisingTrackingEnabled: String = "true"

    func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData) -> Void) {
        appleSearchAdsDataCalled += 1
        completion(appleAttributionDetails!)
    }

    func updateConversionValue(from dispatch: TealiumRequest) {
        updateConversionValueCalled += 1
    }

}
