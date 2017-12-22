//
//  TealiumCollectModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

// MARK:
// MARK: CONSTANTS

enum TealiumCollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let payload = "payload"
    static let responseHeader = "response_headers"
    static let dispatchService = "dispatch_service"
    static let wasQueue = "was_queued"
}

enum TealiumCollectError : Error {
    case collectNotInitialized
    case unknownResponseType
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
}


// MARK:
// MARK: EXTENSIONS

extension Tealium {
    
    /**
     Deprecated - use the track(title: String, data: [String:Any]?, completion:((_ success: Bool, _ error: Error?)->Void) function instead. Convience method to track event with optional data.
     
     - parameters:
        - encodedURLString: Encoded string that will be used for the end point for the request
        - completion: Optional callback
     */
    @available(*, deprecated, message: "No longer supported. Will be removed next version.")
    func track(encodedURLString: String,
               completion: ((_ successful: Bool, _ encodedURLString: String, _ error: NSError?)->Void)?){
        
        collect()?.send(finalStringWithParams: encodedURLString,
                        completion: { (success, info,  error) in
                            
                // Make new call but return empty responses for encodedURLString and error
                var encodedURLString = ""
                if let encodedURLStringRaw = info?[TealiumCollectKey.encodedURLString] as? String {
                    encodedURLString = encodedURLStringRaw
                }
                            
                // TODO: convert error to NSError
                completion?(success, encodedURLString, nil)
                            
        }) 
    }
    
    public func collect() -> TealiumCollect? {
        
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }
        
        return collectModule.collect
        
    }
    
}

extension TealiumConfig {
    
    public func setCollectOverrideURL(string: String) {
        
        optionalData[TealiumCollectKey.overrideCollectUrl] = string
    }
    
}


// MARK:
// MARK: MODULE SUBCLASS

/**
 Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
 */
class TealiumCollectModule : TealiumModule {
    
    var collect : TealiumCollect?

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1000,
                                   build: 4,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
       
        isEnabled = true
        
        if self.collect == nil {
            // Collect dispatch service
            var urlString : String
            if let collectURLString = request.config.optionalData[TealiumCollectKey.overrideCollectUrl] as? String{
                urlString = collectURLString
            } else {
                urlString = TealiumCollect.defaultBaseURLString()
            }
            self.collect = TealiumCollect(baseURL: urlString)
        }
        
        didFinish(request)
        
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        isEnabled = false
        
        self.collect = nil
        
        didFinish(request)

    }

    override func track(_ track: TealiumTrackRequest) {
        
        if isEnabled == false {
            didFinishWithNoResponse(track)
            return
        }
        
        guard let collect = self.collect else {
            // TODO: Queue instead?
            didFailToFinish(track,
                            error: TealiumCollectError.collectNotInitialized)
            return
        }
        
        // Send the current track call
        dispatch(track,
                 collect: collect)
        
    }
    
    func didFinish(_ request: TealiumRequest,
                   info: [String:Any]?) {
        
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of:self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        response.info = info
        newRequest.moduleResponses.append(response)
        
        delegate?.tealiumModuleFinished(module: self,
                                        process: newRequest)
    }
    
    func didFailToFinish(_ request: TealiumRequest,
                         info: [String:Any]?,
                         error: Error) {
        
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of:self).moduleConfig().name,
                                             success: false,
                                             error: error)
        response.info = info
        newRequest.moduleResponses.append(response)
        delegate?.tealiumModuleFinished(module: self,
                                        process: newRequest)
        
    }
    
    func dispatch(_ track: TealiumTrackRequest,
                  collect: TealiumCollect) {
    
        var newData = track.data
        newData[TealiumCollectKey.dispatchService] = TealiumCollectKey.moduleName

        collect.dispatch(data: newData, completion: { [weak self] (success, info, error) in

            // if self deallocated, stop further track processing
            guard let _ = self else {
                return
            }

            track.completion?(success, info, error)

            // Let the modules manager know we had a failure.
            if success == false {
                var localError = error
                if localError == nil { localError = TealiumCollectError.unknownIssueWithSend }
                self?.didFailToFinish(track,
                                      info: info,
                                      error: localError!)
                return
            }
            
            // Another message to moduleManager of completed track, this time of
            //  modified track data.
            self?.didFinish(track,
                            info: info)
            
        })
    }

}

// MARK:
// MARK: COLLECT

import Dispatch

/**
 Internal class for processing data dispatches to delivery endpoint.
 */
public class TealiumCollect {
    
    fileprivate var _baseURL : String
    
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
    public class func defaultBaseURLString() -> String {
        
        return "https://collect.tealiumiq.com/vdata/i.gif?"
        
    }
    
    /**
     Packages data sources into expecteed URL call format and sends
     
     - Parameters:
     - Data: dictionary of all key-values to bve sent with dispatch.
     - completion: passes a completion to send function
     */
    public func dispatch(data: [String: Any],
                         completion:((_ success:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?){
        
        let sanitizedData = TealiumCollect.sanitized(dictionary: data)
        let encodedURLString: String = _baseURL + encode(dictionary: sanitizedData)
        
        send(finalStringWithParams: encodedURLString) { (success, info, error) in
            
            guard let completion = completion else {
                // No callback requested
                return
            }
            
            var aggregateInfo = [TealiumCollectKey.payload:sanitizedData ] as [String:Any]
            if let info = info {
                aggregateInfo += info
            }
            
            completion(success, aggregateInfo, error)
            
        }
    }
    
    
    // MARK: INTERNAL METHODS
    
    /**
     Sends final dispatch to its endpoint
     
     - Parameters:
     - FinalStringWithParams: The encoded url string to send
     - completion: Depending on network responses the completion will pass a success/failure, the string sent, and an error if it exists.
     
     */
    
    internal func send(finalStringWithParams : String , completion:((_ success:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?) {
        let url = URL(string: finalStringWithParams)
        let request = URLRequest(url: url!)
        
        let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in
            
            var info = [TealiumCollectKey.encodedURLString: finalStringWithParams ,
                        TealiumCollectKey.dispatchService: TealiumCollectKey.moduleName ] as [String: Any]
            
            if  (error != nil) {
                completion?(false, info, error as Error?)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(false, info, TealiumCollectError.unknownResponseType)
                return
            }
            
            
            info += [TealiumCollectKey.responseHeader: self.headerResponse(response: httpResponse) ]
            
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
    
    internal func headerResponse(response: HTTPURLResponse) -> [String:Any] {
        
        guard let dict = response.allHeaderFields as? [String:Any] else {
            
            // Go through each field and populate manually
            
            let headerFields = response.allHeaderFields
            let keys = headerFields.keys
            var mDict = [String:Any]()
            
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
    
    /**
     Encodes a string based on Vdata specs
     
     - Parameters:
     - Dictionary: The dictionary of data sources to be encoded
     
     - Returns:
     - String:  encoded string
     */
    internal func encode(dictionary:[String:Any])-> String {
        
        let keys = dictionary.keys
        let sortedKeys = keys.sorted { $0 < $1 }
        var encodedArray = [String]()
        
        for key in sortedKeys {
            
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            var value = dictionary[key]
            
            if let valueString = value as? String{
                
                value = valueString
            } else if let stringArray = value as? [String]{
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
    class func sanitized(dictionary:[String:Any]) -> [String:Any]{
        
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

