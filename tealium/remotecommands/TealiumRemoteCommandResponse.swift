//
//  TealiumRemotCommandReponse.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandResponseError : Error {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}

class TealiumRemoteCommandResponse : CustomStringConvertible {
    
    var status : Int = TealiumRemoteCommandStatusCode.noContent.rawValue
    var urlRequest : URLRequest
    var urlResponse : URLResponse?
    var data: Data?
    var error : Error?
    
    var description : String {
        return "<TealiumRemoteCommandResponse: config:\(config()), status:\(status), payload:\(payload()), response: \(urlResponse), data:\(data) error:\(error)>"
    }
    
    convenience init?(urlString: String) {
        
        // Convert string to url request then process as usual
        guard let url = URL(string: urlString) else {
            return nil
        }
        let urlRequest = URLRequest(url: url)
        self.init(request: urlRequest)
    }
    
    /*
     Constructor for a Tealium Remote Command. Fails if the request was not
     formatted correctly for remote command use.
     */
    init?(request: URLRequest) {
        
        self.urlRequest = request

        guard let requestData = requestDataFrom(request: request) else {
            return nil
        }
        guard let _ = configFrom(requestData: requestData) else {
            return nil
        }
        guard let _ = payloadFrom(requestData: requestData) else {
            return nil
        }
        
    }
    
    func requestDataFrom(request: URLRequest) -> [String:Any]? {
        
        guard let paramData = TealiumRemoteCommandResponse.paramDataFrom(request) else {
            return nil
        }
        guard let requestDataString = paramData["request"] as? String else {
            return nil
        }
        guard let requestData = TealiumRemoteCommandResponse.convertToDictionary(text: requestDataString) else {
            return nil
        }
        return requestData
    }
    
    func configFrom(requestData:[String:Any]) -> [String:Any]? {
        
        guard let config = requestData["config"] as? [String:Any] else {
            return nil
        }
        return config
        
    }
    
    func payloadFrom(requestData:[String:Any]) -> [String:Any]? {
        guard let payload = requestData["payload"] as? [String:Any] else {
            return nil
        }
        return payload
    }
    
    func config() -> [String:Any] {
        let requestData = requestDataFrom(request: self.urlRequest)!
        let config = configFrom(requestData: requestData)!
        return config
    }
    
    func payload() -> [String:Any] {
        let requestData = requestDataFrom(request: self.urlRequest)!
        let payload = payloadFrom(requestData: requestData)!
        return payload
    }
    
    class func convertToDictionary(text: String) -> [String: Any]? {
        
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            return nil
        }
        
    }
    
    class func paramDataFrom(_ request: URLRequest) -> [String:Any]? {
        
        guard let url = request.url else {
            return nil
        }
        
        return url.queryItems

    }
    
}
