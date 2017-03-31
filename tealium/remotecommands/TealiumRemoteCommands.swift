//
//  TealiumRemoteCommands.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/2/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandsHTTPKey {
    static let authenticate = "authenticate"
    static let body = "body"
    static let headers = "headers"
    static let method = "method"
    static let parameters = "parameters"
    static let password = "password"
    static let responseId = "response_id"
    static let url = "url"
    static let username = "username"
}


enum TealiumRemoteCommandsError : Error {
    case invalidScheme
    case noCommandIdFound
    case noCommandForCommandIdFound
    case remoteCommandsDisabled
    case requestNotProperlyFormatted
}

protocol TealiumRemoteCommandsDelegate : class {
    func tealiumRemoteCommandCompleted(jsString:String, response:TealiumRemoteCommandResponse)
}

public class TealiumRemoteCommands : NSObject {
    
    var commands = [TealiumRemoteCommand]()
    var isEnabled = false
    var schemeProtocol = "tealium"
    
    func isAValidRemoteCommand(request: URLRequest) -> Bool {
        
        if request.url?.scheme == self.schemeProtocol{
            return true
        }
        
        return false
    }
    
    func add(_ remoteCommand : TealiumRemoteCommand) {
        
        // NOTE: Multiple commands with the same command id are possible - OK
        commands.append(remoteCommand)
    }
    
    func remove(commandWithId: String) {
        commands.removeCommandForId(commandWithId)
    }
    
    func enable() {
        isEnabled = true
    }
    
    func disable() {
        isEnabled = false
    }
    
    
    /// Trigger an associated remote command from a string representation of a url request. Function
    ///     will presume the string is escaped, if not, will attempt to escape string 
    ///     with .urlQueryAllowed. NOTE: using .urlHostAllowed for escaping will not work.
    ///
    /// - Parameter urlString: Url string including host, ie: tealium://commandId?request={}...
    /// - Returns: Error if unable to trigger a remote command. Can ignore if the url was not
    ///     intended for a remote command.
    func triggerCommandFrom(urlString: String) -> TealiumRemoteCommandsError? {

        var urlInitial = URL(string: urlString)
        if urlInitial == nil {
            guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return TealiumRemoteCommandsError.requestNotProperlyFormatted
            }
            urlInitial = URL(string: escapedString)
        }
        guard let url = urlInitial else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        let request = URLRequest(url: url)
        return triggerCommandFrom(request: request)

    }
    
    
    /// Trigger an associated remote command from a url request.
    ///
    /// - Parameter request: URLRequest to check for a remote command.
    /// - Returns: Error if unable to trigger a remote command. If nil is returned,
    ///     then call was a successfully triggered remote command.
    func triggerCommandFrom(request : URLRequest) -> TealiumRemoteCommandsError? {
        
        if request.url?.scheme != self.schemeProtocol{
            return TealiumRemoteCommandsError.invalidScheme
        }
        guard let commandId = request.url?.host else {
            return TealiumRemoteCommandsError.noCommandIdFound
        }
        guard let command = commands.commandForId(commandId) else {
            return TealiumRemoteCommandsError.noCommandForCommandIdFound
        }
        guard let response = TealiumRemoteCommandResponse(request: request) else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        if isEnabled == false {
            // Was valid remote command, but we're disabled at the moment.
            return nil
        }
        command.completeWith(response: response)
        return nil
        
    }
    
}


extension Array where Element: TealiumRemoteCommand {

    func commandForId(_ commandId : String) -> TealiumRemoteCommand? {
        return self.filter({ $0.commandId == commandId}).first
    }
    
    mutating func removeCommandForId(_ commandId: String){
        for (index,command) in self.reversed().enumerated() {
            if command.commandId == commandId {
                self.remove(at: index)
            }
        }
    }
    
}

/*
 
 ===========
 SAMPLE CALL
 ===========
 
 tealium://logger?request={"config":{},"payload":{"lifecycle_firstlaunchdate_MMDDYYYY":"02/16/2017","lifecycle_dayssincelastwake":"4","autotracked":"true","tealium_datasource":"testDatasource","lifecycle_diddetectcrash":"true","lifecycle_hourofday_local":"12","dispatch_service":"tagmanagement","app_uuid":"F6CB6C0A-0FC9-4719-9D32-B78EC495C788","lifecycle_totalcrashcount":"40","lifecycle_lastwakedate":"2017-03-09T00:51:39Z","tealium_timestamp_epoch":"1489432102.31095","tealium_session_id":"1489432096135.25","link_id":"testCommand","lifecycle_isfirstwaketoday":"true","lifecycle_totallaunchcount":"42","tealium_vid":"F7CB6B0A0FC947199D32B78EC495C789","lifecycle_lastlaunchdate":"2017-03-09T00:51:39Z","lifecycle_totalsleepcount":"41","device_advertising_id":"F86BE802-B42C-4C4C-8F7B-60A3F9EDA7B5","lifecycle_secondsawake":"0","tealium_library_name":"swift","lifecycle_dayofweek_local":"2","tealium_visitor_id":"F7CB6B0A0FC947199D32B78EC495C789","lifecycle_totalwakecount":"42","lifecycle_sleepcount":"0","lifecycle_firstlaunchdate":"2017-02-16T19:15:20Z","tealium_profile":"demo","tealium_account":"tealiummobile","tealium_random":"0896866425171567","tealium_environment":"dev","lifecycle_type":"launch","lifecycle_dayssincelaunch":"24","lifecycle_launchcount":"42","lifecycle_wakecount":"42","lifecycle_priorsecondsawake":"0","lifecycle_totalsecondsawake":"0","tealium_library_version":"1.1.3","cp.utag_main_v_id":"015a9327f11e001ef6deae7774340006c004006400432","cp.utag_main__sn":"5","cp.utag_main__ss":"0","cp.utag_main__st":"1489433902418","cp.utag_main_dc_visit":"3","cp.utag_main_ses_id":"1489432102230","cp.utag_main__pn":"1","cp.utag_main_dc_event":"7","cp.__utma":"142125879.850793584.1488990599.1488990599.1488997059.2","cp.__utmz":"142125879.1488990599.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)","dom.referrer":"","dom.title":"Tealium Mobile Webview","dom.domain":"tags.tiqcdn.com","dom.query_string":"","dom.hash":"","dom.url":"https://tags.tiqcdn.com/utag/tealiummobile/demo/dev/mobile.html?","dom.pathname":"/utag/tealiummobile/demo/dev/mobile.html","dom.viewport_height":667,"dom.viewport_width":667,"ut.domain":"tiqcdn.com","ut.version":"ut4.42.201703081911","ut.event":"link","ut.visitor_id":"015a9327f11e001ef6deae7774340006c004006400432","ut.session_id":"1489432102230","ut.account":"tealiummobile","ut.profile":"demo","ut.env":"dev","tealium_event":"link","tealium_timestamp_utc":"2017-03-13T19:08:22.418Z","tealium_timestamp_local":"2017-03-13T12:08:22.418"}}

 
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
 
 
 ================
 CALLBACK EXAMPLE
 ================
 
 // Original objc js command to pass back into webview after remote command complete (permits reporting and chaining)
 
 NSString *callBackCommand = [NSString stringWithFormat:@"try {\
 utag.mobile.remote_api.response[\"%@\"][\"%@\"](\"%li\", '%@');\
 }catch(err) {\
 console.error(err);\
 }\
 ", response.commandId, response.responseId, (long)response.status, response.body];
 
 */
