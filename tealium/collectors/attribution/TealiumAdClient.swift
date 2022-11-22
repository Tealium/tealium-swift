//
//  TealiumAdClient.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import AdServices
import Foundation
import iAd

/// Testable replacement for Apple's AdClient.
public protocol TealiumAdClientProtocol {
    static var shared: TealiumAdClientProtocol { get }
    func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void)
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}

/// Implements Apple's AdClient to retrieve Apple Search Ads data.
public class TealiumAdClient: TealiumAdClientProtocol {
    let adClient = ADClient.shared()
    public static var shared: TealiumAdClientProtocol = TealiumAdClient()

    private init() {

    }

    public func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        if #available(iOS 14.3, *) {
            if let adAttributionToken = try? AAAttribution.attributionToken() {
                guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
                    completionHandler(nil, AdServiceErrors.invalidUrl)
                    return
                }
                let request = NSMutableURLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = adAttributionToken.data(using: .utf8)
                let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, _, error in
                    if let error = error {
                        completionHandler(nil, error)
                        return
                    }
                    do {
                        guard let data = data else {
                            completionHandler(nil, AdServiceErrors.nilData)
                            return
                        }
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: NSObject] {
                            print(data.prettyPrintedJSONString)
                            completionHandler(jsonResponse, nil)
                            return
                        } else {
                            completionHandler(nil, AdServiceErrors.invalidJson)
                            return
                        }
                    } catch {
                        completionHandler(nil, error)
                    }
                })
                task.resume()
            } else {
                completionHandler(nil, AdServiceErrors.invalidToken)
            }
        } else {
            adClient.requestAttributionDetails(completionHandler)
        }
    }
}

public extension TealiumAdClient {
    enum AdServiceErrors: Error {
        case invalidUrl
        case invalidJson
        case nilData
        case invalidToken
    }
}
#endif
