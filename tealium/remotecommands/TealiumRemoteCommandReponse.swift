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
    
    let config : [String:Any]
    var status : TealiumRemoteCommandStatusCode = .unknown
    var payload : [String:Any]
    var error : Error?
    
    var description : String {
        return "<TealiumRemoteCommandResponse: config:\(config), status:\(status), payload:\(payload), error:\(error)>"
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
        
        guard let paramData = TealiumRemoteCommandResponse.paramDataFrom(request) else {
            return nil
        }
        guard let requestDataString = paramData["request"] as? String else {
            return nil
        }
        guard let requestData = TealiumRemoteCommandResponse.convertToDictionary(text: requestDataString) else {
            return nil
        }
        guard let config = requestData["config"] as? [String:Any] else {
            return nil
        }
        guard let payload = requestData["payload"] as? [String:Any] else {
            return nil
        }
        self.config = config
        self.payload = payload
        
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
