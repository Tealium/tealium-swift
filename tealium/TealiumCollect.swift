//
//  tealiumCollect.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

/**
    Internal class for processing data dispatches to delivery endpoint.
 
 */
class TealiumCollect {

    private var _baseURL : String
    
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
    func dispatch(data: [String: AnyObject], completion:((success:Bool, encodedURLString: String, error: NSError?) -> Void)?){
    
        let sanitizedData = sanitized(data)
        let dispatchString: String = _baseURL + encode(sanitizedData)
        send(dispatchString, completion: completion)
        
    }
    
    
    // MARK: INTERNAL METHODS
    
    /**
     Sends final dispatch to its endpoint
     
        - Parameters:
            - FinalStringWithParams: The dictionary of data sources that will be encoded
            - completion: Depending on network responses the completion will pass a success/failure, the string sent, and an error if it exists.

     */
    func send(finalStringWithParams : String , completion:((success:Bool, encodedURLString: String, error: NSError?) -> Void)?) {
        let url = NSURL(string: finalStringWithParams)
        let request = NSMutableURLRequest(URL: url!)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if  (error != nil) {
        
                completion?(success: false, encodedURLString: finalStringWithParams, error: error)
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
               
                let userInfo = [NSLocalizedDescriptionKey : "Response object was not converted correctly to type    NSHTTPURLResponse",
                                NSLocalizedRecoverySuggestionErrorKey: "Consult Tealium Engineering"]

                
                let err = NSError(domain: "Tealium", code: 1, userInfo: userInfo)
     
                completion?(success: false, encodedURLString: finalStringWithParams, error: err)
                return
            }
            
            if let xerror = (httpResponse.allHeaderFields["x-error"] as? String) {
                   
                let userInfo = [NSLocalizedDescriptionKey : xerror,
                                NSLocalizedFailureReasonErrorKey : xerror,
                                NSLocalizedRecoverySuggestionErrorKey: "Consult Tealium Engineering"]
                    
                let err = NSError(domain: "Tealium", code: 2, userInfo: userInfo)
                    
                completion?(success: false, encodedURLString: finalStringWithParams, error: err)
                    return
            }
                
            if (httpResponse.statusCode != 200) {
                
                let userInfo = [NSLocalizedDescriptionKey : httpResponse.statusCode,
                                NSLocalizedFailureReasonErrorKey : "Status code is not the expected 200",
                                NSLocalizedRecoverySuggestionErrorKey: "Check Base URL to ensure its validity"]

                
                let err = NSError(domain: "Tealium", code: httpResponse.statusCode, userInfo: userInfo as [NSObject : AnyObject])
                
                completion?(success: false, encodedURLString:finalStringWithParams, error: err)
                return
            }
            
            completion?(success: true, encodedURLString: finalStringWithParams, error: error )
            
        }
       
        task.resume()
    
    }
    
    // MARK: INTERNAL HELPERS
    
    /**
     Encodes a string based on Vdata specs
     
     - Parameters:
        - Dictionary: The dictionary of data sources to be encoded
     
     - Returns:
        - String:  encoded string
     */
    func encode(dictionary:[String:AnyObject])-> String {
        
        let keys = dictionary.keys
        let sortedKeys = keys.sort { $0 < $1 }
        var encodedArray = [String]()
        
        for key in sortedKeys {
            
            let encodedKey = key.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            var value = dictionary[key]
                
            if let valueString = value as? String{
                value = valueString
            } else if let stringArray = value as? [String]{
                value = "\(stringArray)"
            } else {
                continue
            }
            
            let encodedValue = value!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            let encodedElement = "\(encodedKey)=\(encodedValue)"
            encodedArray.append(encodedElement)
        }
        
        return encodedArray.joinWithSeparator("&")
    }
    
    /**
        Helper Function for unit testing
     
        - Returns:
            - String : the base url
     
    */
    func getBaseURLString() -> String {
        return _baseURL
    }
    
    /**
        Clears dictionary of any value types not supported by collect
     */
    func sanitized(dictionary:[String:AnyObject]) -> [String:AnyObject]{
    
        var clean = [String: AnyObject]()
        
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
