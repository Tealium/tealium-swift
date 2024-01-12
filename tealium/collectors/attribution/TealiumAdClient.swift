//
//  TealiumAdClient.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import AdServices
import Foundation

/// Testable replacement for Apple's AdClient.
public protocol TealiumAdClientProtocol {
    func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void)
}

public class TealiumHTTPAdClient: TealiumAdClientProtocol {

    public init() {}

    internal func getAttributionData(details: [String: NSObject]?) -> PersistentAttributionData? {
        var appleAttributionDetails = PersistentAttributionData()
        appleAttributionDetails.conversionType = details?[AppleInternalKeys.AAAAttribution.conversionType.rawValue]?.description as? String
        appleAttributionDetails.clickedWithin30D = details?[AppleInternalKeys.AAAAttribution.attribution.rawValue]?.description as? String
        appleAttributionDetails.clickedDate = details?[AppleInternalKeys.AAAAttribution.clickDate.rawValue]?.description as? String
        appleAttributionDetails.adKeyword = details?[AppleInternalKeys.AAAAttribution.keywordId.rawValue]?.description as? String
        appleAttributionDetails.orgId = details?[AppleInternalKeys.AAAAttribution.orgId.rawValue]?.description as? String
        appleAttributionDetails.region = details?[AppleInternalKeys.AAAAttribution.countryOrRegion.rawValue]?.description as? String
        appleAttributionDetails.adGroupId = details?[AppleInternalKeys.AAAAttribution.adGroupId.rawValue]?.description as? String
        appleAttributionDetails.campaignId = details?[AppleInternalKeys.AAAAttribution.campaignId.rawValue]?.description as? String
        appleAttributionDetails.adId = details?[AppleInternalKeys.AAAAttribution.adId.rawValue]?.description as? String
        return appleAttributionDetails
    }

    public func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void) {
        guard #available(iOS 14.3, *) else {
            completionHandler(nil, nil)
            return
        }
        guard let adAttributionToken = try? AAAttribution.attributionToken() else {
            completionHandler(nil, AdServiceErrors.invalidToken)
            return
        }
        guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
            completionHandler(nil, AdServiceErrors.invalidUrl)
            return
        }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = adAttributionToken.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { [weak self] data, _, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            do {
                guard let data = data else {
                    completionHandler(nil, AdServiceErrors.nilData)
                    return
                }
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: NSObject] else {
                    completionHandler(nil, AdServiceErrors.invalidJson)
                    return
                }
                completionHandler(self?.getAttributionData(details: jsonResponse), nil)
            } catch {
                completionHandler(nil, error)
            }
        })
        task.resume()
    }
}

public extension TealiumHTTPAdClient {
    enum AdServiceErrors: Error {
        case invalidUrl
        case invalidJson
        case nilData
        case invalidToken
    }
}
#endif
