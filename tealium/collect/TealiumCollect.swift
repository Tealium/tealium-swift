//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/11/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Dispatch
import Foundation
#if collect
import TealiumCore
#endif

/// Internal class for processing data dispatches to delivery endpoint.
public class TealiumCollect: TealiumCollectProtocol {

    fileprivate var _baseURL: String

    // MARK: PUBLIC METHODS

    /// Initializer for creating an Instance of Tealium Collect
    ///
    /// - Parameters:
    /// - baseURL: Base url for collect end point
    init(baseURL: String) {
        // not compatible with vdata endpoint - default to event endpoint
        if baseURL.contains("/event") {
            _baseURL = TealiumCollect.defaultBaseURLString()
        } else {
            _baseURL = baseURL
        }
    }

    /// Class level function for the default base url
    ///
    /// - Returns:
    /// - Base URL string target for dispatches
    public class func defaultBaseURLString() -> String {
        return "https://collect.tealiumiq.com/vdata/i.gif?"
    }

    /// Dispatches data to an HTTP endpoint, then calls optional completion block when finished
    ///
    /// - Parameters:
    /// - data: [String:Any] of variables to be dispatched
    /// - completion: Optional completion block to be called when operation complete
    public func dispatch(data: [String: Any],
                         completion: TealiumCompletion?) {
        let sanitizedData = TealiumCollect.sanitized(dictionary: data)
        let encodedURLString: String = _baseURL + encode(dictionary: sanitizedData)

        send(finalStringWithParams: encodedURLString) { success, info, error in

            guard let completion = completion else {
                // No callback requested
                return
            }

            var aggregateInfo = [TealiumCollectKey.payload: sanitizedData ] as [String: Any]
            if let info = info {
                aggregateInfo += info
            }

            completion(success, aggregateInfo, error)
        }
    }

    // MARK: INTERNAL METHODS

    /// Sends final dispatch to its endpoint
    ///
    /// - Parameters:
    /// - finalStringWithParams: The encoded url string to send
    /// - completion: Depending on network responses the completion will pass a success/failure, the string sent, and an error if it exists.
    func send(finalStringWithParams: String, completion: TealiumCompletion?) {
        let url = URL(string: finalStringWithParams)
        let request = URLRequest(url: url!)

        let task = URLSession.shared.dataTask(with: request, completionHandler: { _, response, error in
            var info = [TealiumCollectKey.encodedURLString: finalStringWithParams ,
                        TealiumKey.dispatchService: TealiumCollectKey.moduleName ] as [String: Any]

            if error != nil {
                completion?(false, info, error as Error?)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(false, info, TealiumCollectError.unknownResponseType)
                return
            }

            info += [TealiumCollectKey.responseHeader: self.headerResponse(response: httpResponse) ]

            if httpResponse.allHeaderFields[TealiumCollectKey.errorHeaderKey] as? String != nil {
                completion?(false, info, TealiumCollectError.xErrorDetected)
                return
            }

            if httpResponse.statusCode != 200 {
                completion?(false, info, TealiumCollectError.non200Response)
                return
            }

            completion?(true, info, nil )
        })

        task.resume()
    }

    /// Grabs the header response fields from a URL response
    /// - Parameter response: URLResponse object
    /// - Returns: [String: Any] representation of header fields
    func headerResponse(response: HTTPURLResponse) -> [String: Any] {
        guard let dict = response.allHeaderFields as? [String: Any] else {

            // Go through each field and populate manually

            let headerFields = response.allHeaderFields
            let keys = headerFields.keys
            var mDict = [String: Any]()

            for key in keys {
                guard let stringKey = key as? String else {
                    continue
                }
                let value = headerFields[key]
                mDict[stringKey] = value
            }

            return mDict
        }

        return dict
    }

    // MARK: INTERNAL HELPERS

    /// Encodes a string based on Vdata specs
    ///
    /// - Parameters:
    /// - Dictionary: The dictionary of variables to be encoded
    ///
    /// - Returns: Encoded URL-safe String representing the dictionary passed in
    func encode(dictionary: [String: Any]) -> String {
        let keys = dictionary.keys
        let sortedKeys = keys.sorted { $0 < $1 }
        var encodedArray = [String]()

        for key in sortedKeys {

            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            var value = dictionary[key]

            if let valueString = value as? String {
                value = valueString
            } else if let stringArray = value as? [String] {
                value = "\(stringArray)"
            } else {
                continue
            }

            guard let valueString = value as? String else {
                continue
            }
            let encodedValue = valueString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

            let encodedElement = "\(encodedKey)=\(encodedValue)"
            encodedArray.append(encodedElement)
        }

        return encodedArray.joined(separator: "&")
    }

    /// Helper Function for unit testing
    ///
    /// - Returns:
    /// - String : the base url
    func getBaseURLString() -> String {
        return _baseURL
    }

    /// Clears dictionary of any value types not supported by collect
    ///
    /// - Parameter dictionary: [String: Any] to be sanitized
    /// - Returns: [String: Any] of sanitized data
    class func sanitized(dictionary: [String: Any]) -> [String: Any] {
        var clean = [String: Any]()

        for (key, value) in dictionary {

            if value is String ||
                value is [String] {

                clean[key] = value

            } else {

                let stringified = "\(value)"

                clean[key] = stringified
            }
        }

        return clean
    }
}
