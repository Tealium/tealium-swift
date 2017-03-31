//
//  TealiumRemoteHTTPCommand.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteHTTPCommandKey {
    static let commandId = "_http"
    static let jsCommand = "js"
    static let notificationName = "com.tealium.remotecommand.http"
}

let TealiumHTTPRemoteCommandQueue = DispatchQueue(label: "com.tealium.remotecommand.http")

//extension TealiumRemoteCommands : UIWebViewDelegate {
// 
//    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        
//        if self.triggerCommandFrom(request: request) != nil {
//            // TODO: Error reporting
//            return false
//        }
//        return true
//        
//    }
//}

class TealiumRemoteHTTPCommand : TealiumRemoteCommand {
    
    class func httpCommand(forQueue: DispatchQueue) -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: TealiumRemoteHTTPCommandKey.commandId,
                                    description: "For processing tag-triggered HTTP requests",
                                    queue: forQueue) { (response) in
                                        
            guard response is TealiumRemoteHTTPCommandResponse else {
                // Response not formatted for HTTP Calls
                return
            }
                
            let requestInfo = TealiumRemoteHTTPCommand.httpRequest(payload: response.payload)
                                        
            // TODO: Error handling?
            guard let request = requestInfo.request else {
                return
            }
                                        
            let task = URLSession.shared.dataTask(with: request,
                                                  completionHandler: { (data, urlResponse, error) in
                                                    
                    TealiumRemoteHTTPCommand.sendCompletionNotificationFor(commandId: TealiumRemoteHTTPCommandKey.commandId,
                                                                           response: response)
            })
            
            task.resume()
                        
        }
    }
    
    
    class func httpRequest(payload: [String:Any]) -> (request: URLRequest?, error: Error?) {
        
        guard let urlStringValue = payload[TealiumRemoteCommandsHTTPKey.url] as? String else {
            // This response is not intended for use as an HTTP command
            return (nil, TealiumRemoteCommandResponseError.missingURLTarget)
        }
        
        guard let method = payload[TealiumRemoteCommandsHTTPKey.method] as? String else {
            // No idea what sort of URL call we should be making
            return (nil, TealiumRemoteCommandResponseError.missingURLMethod)
        }
        
        var urlComponents = URLComponents(string: urlStringValue)
        
        if let paramsData = payload[TealiumRemoteCommandsHTTPKey.parameters] as? [String:Any] {
            let paramQueryItems = TealiumRemoteHTTPCommand.paramItemsFrom(dictionary: paramsData)
            urlComponents?.queryItems = paramQueryItems
        }
        
        guard let url = urlComponents?.url else {
            return (nil, TealiumRemoteCommandResponseError.couldNotConvertDataToURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let headersData = payload[TealiumRemoteCommandsHTTPKey.headers] as? [String:Any] {
            request.assignHeadersFrom(dictionary: headersData)
        }
        if let body = payload["body"] as? String {
            request.httpBody = body.data(using: .utf8)
            request.addValue("\([UInt8](body.utf8))", forHTTPHeaderField: "content-length")
        }
        
        if let authenticationData = payload[TealiumRemoteCommandsHTTPKey.authenticate] as? [String:Any] {

            if let username = authenticationData["username"] as? String,
                let password = authenticationData["password"] as? String {
                
                let loginString = "\(username):\(password)"
                let loginData = loginString.data(using: String.Encoding.utf8)!
                let base64LoginString = loginData.base64EncodedString()
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            
            }
        }
        
        return (request, nil)
        
    }
    
    class func paramItemsFrom(dictionary: [String:Any]) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            guard let value = dictionary[key] as? String else {
                continue
            }
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        return queryItems
    }
    
    class func sendCompletionNotificationFor(commandId:String, response:TealiumRemoteCommandResponse) {
        
        guard let response = response as? TealiumRemoteHTTPCommandResponse else {
            return
        }
        
        let notification = TealiumRemoteHTTPCommand.completionNotificationFor(commandId: commandId,
                                                                              response: response)
        NotificationCenter.default.post(notification)
    }
    
    class func completionNotificationFor(commandId:String,
                                         response:TealiumRemoteHTTPCommandResponse) -> Notification {
        
        let jsString = "try { utag.mobile.remote_api.response[\(commandId)][\(response.responseId())](\(response.status),\(response.body()))} catch(err) {console.error(err}}"
        let notificationName = Notification.Name(rawValue: TealiumRemoteHTTPCommandKey.notificationName)
        let notification = Notification(name: notificationName,
                                        object: self,
                                        userInfo: [TealiumRemoteHTTPCommandKey.jsCommand:jsString])
        return notification
    }
    
    override func completeWith(response: TealiumRemoteCommandResponse) {
        
        self._completion(response)
        
    }

}

class TealiumRemoteHTTPCommandResponse : TealiumRemoteCommandResponse {
    
    override var description: String {
        return "<TealiumRemoteCommandResponse: config:\(config), responseId:\(responseId), status:\(status), body:\(body), payload:\(payload), error:\(error)>"
    }
    
    func responseId() -> String? {
        guard let responseId = config["response"] as? String else {
            return nil
        }
        return responseId
    }
    
    func body() -> String? {
        if let body = payload["body"] as? String {
            return body
        }
        return nil
    }
    
}

/*
 
 ===========
 SAMPLE CALL
 ===========
 
 tealium://_http?request:{"config":{"response_id":"custom_command_14894356495341715"},"payload":{"command_id":"_http","debug":"true","url":"https://c00.adobe.com/v3/910238aa8bbbaf10a7559297f8a0ef7db78ca04841a35477573d78e64091e834/end?a_ugid=https://tags.tiqcdn.com/utag/services-crouse/adobe-acq-test/dev/mobile.html","method":"GET","headers":{"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36"}}}
 
 =============
 CALL TEMPLATE
 =============
 
 var response_id = new Date().getTime();
 
 window.open('tealium://_http?request=' + encodeURIComponent(JSON.stringify({
     config : {
     response_id : response_id
     },
     payload : {
         authenticate : {
         username : '<username>',
         password : '<password>'
         }, // http://username:password@url...
         url : '<url>',
         headers : {
         '<header>' : '<value>'
         },
         parameters : {
         '<someKey>' : '<someValue>'
         },// http://url.com?someKey=someValue...
         body : {
         '<someKey>' : '<someValue>'
         }, // Or String, thought if a given JSON the structure will be converted into a form submission.
         method : '<POST/GET/PUT>'
     }
 })), '_self');
 */
