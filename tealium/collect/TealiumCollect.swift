//
//  tealiumCollect.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation
import Dispatch

/**
    Internal class for processing data dispatches to delivery endpoint.
 */
class TealiumCollect {

    fileprivate var _baseURL : String
    
    // MARK: 
    // MARK: PUBLIC METHODS
    
    /**
     Initializer for creating an Instance of Tealium Collect
     
     - Parameters:
        - baseURL: Base url for collect end point
     */
    init(baseURL: String){
        
        self._baseURL = baseURL
        
    }
    
    /**
     Class level function for the default base url
     
        - Returns:
            - Base URL string target for dispatches
    
     */
    class func defaultBaseURLString() -> String {
        
        return "https://collect.tealiumiq.com/vdata/i.gif?"
        
    }
    
    /**
     Packages data sources into expecteed URL call format and sends
     
     - Parameters:
     - Data: dictionary of all key-values to bve sent with dispatch.
     - completion: passes a completion to send function
     */
    func dispatch(data: [String: AnyObject], completion:((_ success:Bool, _ info:[String:AnyObject]?, _ error: Error?) -> Void)?){
        
        let sanitizedData = TealiumCollect.sanitized(dictionary: data)
        let encodedURLString: String = _baseURL + encode(dictionary: sanitizedData)
        
        send(finalStringWithParams: encodedURLString) { (success, info, error) in
            
            guard let completion = completion else {
                // No callback requested
                return
            }
            
            var aggregateInfo = [TealiumCollectKey.payload:sanitizedData as AnyObject] as [String:AnyObject]
            if let info = info {
                aggregateInfo += info
            }
            
            completion(success, aggregateInfo, error)
            
        }
    }
    
    
    // MARK: 
    // MARK: INTERNAL METHODS
    
    /**
     Sends final dispatch to its endpoint
     
     - Parameters:
         - FinalStringWithParams: The encoded url string to send
         - completion: Depending on network responses the completion will pass a success/failure, the string sent, and an error if it exists.
     
     */
    
    internal func send(finalStringWithParams : String , completion:((_ success:Bool, _ info:[String:AnyObject]?, _ error: Error?) -> Void)?) {
        let url = URL(string: finalStringWithParams)
        let request = URLRequest(url: url!)
        
        let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in

            var info = [TealiumCollectKey.encodedURLString: finalStringWithParams as AnyObject,
                        TealiumCollectKey.dispatchService: TealiumCollectKey.moduleName as AnyObject] as [String: AnyObject]
            
            if  (error != nil) {
                completion?(false, info, error as Error?)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(false, info, TealiumCollectError.unknownResponseType)
                return
            }
            
            info += [TealiumCollectKey.responseHeader: self.headerResponse(response: httpResponse) as AnyObject]
            
            if let _ = (httpResponse.allHeaderFields["X-Error"] as? String) {
                completion?(false, info, TealiumCollectError.xErrorDetected)
                return
            }
            
            if (httpResponse.statusCode != 200) {
                completion?(false, info, TealiumCollectError.non200Response)
                return
            }
            
            completion?(true, info, nil )
            
        })
        
        task.resume()

    }
    
    internal func headerResponse(response: HTTPURLResponse) -> [String:AnyObject] {
        
        guard let dict = response.allHeaderFields as? [String:AnyObject] else {
            
            // Go through each field and populate manually
            
            let headerFields = response.allHeaderFields
            let keys = headerFields.keys
            var mDict = [String:AnyObject]()
            
            for key in keys {
                guard let stringKey = key as? String else {
                    continue
                }
                let value = headerFields[key] as AnyObject
                mDict[stringKey] = value
            }
            
            return mDict
        }
        
        return dict
        
    }
    
    // MARK: 
    // MARK: INTERNAL HELPERS
    
    /**
     Encodes a string based on Vdata specs
     
     - Parameters:
        - Dictionary: The dictionary of data sources to be encoded
     
     - Returns:
        - String:  encoded string
     */
    internal func encode(dictionary:[String:AnyObject])-> String {
        
        let keys = dictionary.keys
        let sortedKeys = keys.sorted { $0 < $1 }
        var encodedArray = [String]()
        
        for key in sortedKeys {
            
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            var value = dictionary[key]
                
            if let valueString = value as? String{
                value = valueString as AnyObject?
            } else if let stringArray = value as? [String]{
                value = "\(stringArray)" as AnyObject?
            } else {
                continue
            }
            
            let encodedValue = value!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let encodedElement = "\(encodedKey)=\(encodedValue)"
            encodedArray.append(encodedElement)
        }
        
        return encodedArray.joined(separator: "&")
    }
    
    /**
        Helper Function for unit testing
     
        - Returns:
            - String : the base url
     
    */
    internal func getBaseURLString() -> String {
        return _baseURL
    }
    
    /**
        Clears dictionary of any value types not supported by collect
     */
    class func sanitized(dictionary:[String:AnyObject]) -> [String:AnyObject]{
    
        var clean = [String: AnyObject]()
        
        for (key, value) in dictionary {
         
            if value is String ||
                value is [String] {

                clean[key] = value
                
            } else {
            
                let stringified = "\(value)"
                clean[key] = stringified as AnyObject?
            }

        }
        
        return clean
        
    }
}
