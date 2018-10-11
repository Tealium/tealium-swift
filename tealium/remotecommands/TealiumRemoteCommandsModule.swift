//
//  TealiumRemoteCommandsModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//
//  See https://github.com/Tealium/tagbridge for spec reference.

import Foundation

// MARK: 
// MARK: CONSTANTS

enum TealiumRemoteCommandsKey {
    static let moduleName = "remotecommands"
    static let disable = "disable_remote_commands"
    static let disableHTTP = "disable_remote_command_http"
    static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
}

enum TealiumRemoteCommandsModuleError: LocalizedError {
    case wasDisabled

    public var errorDescription: String? {
        switch self {
        case .wasDisabled:
            return NSLocalizedString("Module disabled by config setting.", comment: "RemoteCommandModuleDisabled")
        }
    }
}

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func remoteCommands() -> TealiumRemoteCommands? {
        guard let module = modulesManager.getModule(forName: TealiumRemoteCommandsKey.moduleName) as? TealiumRemoteCommandsModule else {
            return nil
        }

        return module.remoteCommands
    }
}

public extension TealiumConfig {

    func disableRemoteHTTPCommand() {
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = true
    }

    func enableRemoteHTTPCommand() {
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = false
    }

}

// MARK: 
// MARK: MODULE SUBCLASS

class TealiumRemoteCommandsModule: TealiumModule {

    var remoteCommands: TealiumRemoteCommands?

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumRemoteCommandsKey.moduleName,
                                   priority: 1200,
                                   build: 3,
                                   enabled: true)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        remoteCommands?.disable()
        remoteCommands = nil
        didFinish(request)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config
        remoteCommands = TealiumRemoteCommands()
        remoteCommands?.queue = config.dispatchQueue()
        remoteCommands?.enable()
        updateReserveCommands(config: config)
        didFinish(request)
    }

    func enableNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trigger),
                                               name: NSNotification.Name(rawValue: TealiumRemoteCommandsKey.tagmanagementNotification),
                                               object: nil)
    }

    @objc
    func trigger(sender: Notification) {
        guard let request = sender.userInfo?[TealiumRemoteCommandsKey.tagmanagementNotification] as? URLRequest else {
            return
        }
        // TODO: Error handling
        _ = remoteCommands?.triggerCommandFrom(request: request)
    }

    func updateReserveCommands(config: TealiumConfig) {
        // Default option
        var shouldDisable = false

        if let shouldDisableSetting = config.optionalData[TealiumRemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }

        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: TealiumRemoteHTTPCommandKey.commandId)
        } else if remoteCommands?.commands.commandForId(TealiumRemoteHTTPCommandKey.commandId) == nil {
            let httpCommand = TealiumRemoteHTTPCommand.httpCommand()
            remoteCommands?.add(httpCommand)
            enableNotifications()
        }
        // No further processing required - HTTP remote command already up.
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: 
// MARK: REMOTE COMMAND

enum TealiumRemoteCommandStatusCode: Int {
    case unknown = 0
    case success = 200
    case noContent = 204
    case malformed = 400
    case failure = 404
}

protocol TealiumRemoteCommandDelegate: class {

    func tealiumRemoteCommandRequestsExecution(_ command: TealiumRemoteCommand,
                                               response: TealiumRemoteCommandResponse)

}

// MARK: 
// MARK: REMOTE COMMANDS
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

public enum TealiumRemoteCommandsError: Error {
    case invalidScheme
    case noCommandIdFound
    case noCommandForCommandIdFound
    case remoteCommandsDisabled
    case requestNotProperlyFormatted
}

protocol TealiumRemoteCommandsDelegate: class {

    func tealiumRemoteCommandCompleted(jsString: String, response: TealiumRemoteCommandResponse)

}

extension Array where Element: TealiumRemoteCommand {

    func commandForId(_ commandId: String) -> TealiumRemoteCommand? {
        return self.first(where: { $0.commandId == commandId })
    }

    mutating func removeCommandForId(_ commandId: String) {
        for (index, command) in self.reversed().enumerated() where command.commandId == commandId {
            self.remove(at: index)
        }
    }

}

/*
 
 ===========
 SAMPLE CALL
 ===========
 
 tealium://logger?request={"config":{},"payload":{"lifecycle_firstlaunchdate_MMDDYYYY":"02/16/2017","lifecycle_dayssincelastwake":"4","autotracked":"true","tealium_datasource":"testDatasource","lifecycle_diddetectcrash":"true","lifecycle_hourofday_local":"12","dispatch_service":"tagmanagement","app_uuid":"F6CB6C0A-0FC9-4719-9D32-B78EC495C788","lifecycle_totalcrashcount":"40","lifecycle_lastwakedate":"2017-03-09T00:51:39Z","tealium_timestamp_epoch":"1489432102.31095","tealium_session_id":"1489432096135.25","lifecycle_isfirstwaketoday":"true","lifecycle_totallaunchcount":"42","lifecycle_lastlaunchdate":"2017-03-09T00:51:39Z","lifecycle_totalsleepcount":"41","device_advertising_id":"F86BE802-B42C-4C4C-8F7B-60A3F9EDA7B5","lifecycle_secondsawake":"0","tealium_library_name":"swift","lifecycle_dayofweek_local":"2","tealium_visitor_id":"F7CB6B0A0FC947199D32B78EC495C789","lifecycle_totalwakecount":"42","lifecycle_sleepcount":"0","lifecycle_firstlaunchdate":"2017-02-16T19:15:20Z","tealium_profile":"demo","tealium_account":"tealiummobile","tealium_random":"0896866425171567","tealium_environment":"dev","lifecycle_type":"launch","lifecycle_dayssincelaunch":"24","lifecycle_launchcount":"42","lifecycle_wakecount":"42","lifecycle_priorsecondsawake":"0","lifecycle_totalsecondsawake":"0","tealium_library_version":"1.1.3","cp.utag_main_v_id":"015a9327f11e001ef6deae7774340006c004006400432","cp.utag_main__sn":"5","cp.utag_main__ss":"0","cp.utag_main__st":"1489433902418","cp.utag_main_dc_visit":"3","cp.utag_main_ses_id":"1489432102230","cp.utag_main__pn":"1","cp.utag_main_dc_event":"7","cp.__utma":"142125879.850793584.1488990599.1488990599.1488997059.2","cp.__utmz":"142125879.1488990599.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)","dom.referrer":"","dom.title":"Tealium Mobile Webview","dom.domain":"tags.tiqcdn.com","dom.query_string":"","dom.hash":"","dom.url":"https://tags.tiqcdn.com/utag/tealiummobile/demo/dev/mobile.html?","dom.pathname":"/utag/tealiummobile/demo/dev/mobile.html","dom.viewport_height":667,"dom.viewport_width":667,"ut.domain":"tiqcdn.com","ut.version":"ut4.42.201703081911","ut.event":"link","ut.visitor_id":"015a9327f11e001ef6deae7774340006c004006400432","ut.session_id":"1489432102230","ut.account":"tealiummobile","ut.profile":"demo","ut.env":"dev","tealium_event":"link","tealium_timestamp_utc":"2017-03-13T19:08:22.418Z","tealium_timestamp_local":"2017-03-13T12:08:22.418"}}
 
 
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

// MARK: 
// MARK: REMOTE COMMAND RESPONSE
enum TealiumRemoteCommandResponseError: Error {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}

public class TealiumRemoteCommandResponse: CustomStringConvertible {

    public var status: Int = TealiumRemoteCommandStatusCode.noContent.rawValue
    public var urlRequest: URLRequest
    public var urlResponse: URLResponse?
    public var data: Data?
    public var error: Error?

    public var description: String {
        return "<TealiumRemoteCommandResponse: config:\(config()), status:\(status), payload:\(payload()), response: \(String(describing: urlResponse)), data:\(String(describing: data)) error:\(String(describing: error))>"
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
        guard configFrom(requestData: requestData) != nil else {
            return nil
        }
        guard payloadFrom(requestData: requestData) != nil else {
            return nil
        }
    }

    func requestDataFrom(request: URLRequest) -> [String: Any]? {
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

    public func configFrom(requestData: [String: Any]) -> [String: Any]? {
        guard let config = requestData["config"] as? [String: Any] else {
            return nil
        }
        return config
    }

    public func payloadFrom(requestData: [String: Any]) -> [String: Any]? {
        guard let payload = requestData["payload"] as? [String: Any] else {
            return nil
        }
        return payload
    }

    public func config() -> [String: Any] {
        let requestData = requestDataFrom(request: self.urlRequest)!
        let config = configFrom(requestData: requestData)!
        return config
    }

    public func payload() -> [String: Any] {
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

    class func paramDataFrom(_ request: URLRequest) -> [String: Any]? {
        guard let url = request.url else {
            return nil
        }

        return url.queryItems
    }

}

// MARK: 
// MARK: REMOTE HTTP COMMAND
enum TealiumRemoteHTTPCommandKey {
    static let commandId = "_http"
    static let jsCommand = "js"
    static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
}

let tealiumHTTPRemoteCommandQueue = DispatchQueue(label: "com.tealium.remotecommand.http")

public extension URL {

    var queryItems: [String: Any] {
        var params = [String: Any]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { _, item -> [String: Any] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }

}

extension URLRequest {

    func asDictionary() -> [String: Any] {
        var result = [String: Any]()

        result["allowsCellularAccess"] = self.allowsCellularAccess ? "true" : "false"
        result["allHTTPHeaderFields"] = self.allHTTPHeaderFields
        result["cachePolicy"] = self.cachePolicy
        result["url"] = self.url?.absoluteString
        result["timeoutInterval"] = self.timeoutInterval
        result["httpMethod"] = self.httpMethod
        result["httpShouldHandleCookies"] = self.httpShouldHandleCookies
        result["httpShouldUsePipelining"] = self.httpShouldUsePipelining

        return result
    }

    mutating func assignHeadersFrom(dictionary: [String: Any]) {
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            guard let value = dictionary[key] as? String else {
                continue
            }
            self.addValue(value, forHTTPHeaderField: key)
        }
    }
}

extension URLQueryItem {

    var dictionaryRepresentation: [String: Any]? {
        if let value = value {
            return [name: value]
        }
        return nil
    }

}

class TealiumRemoteHTTPCommand: TealiumRemoteCommand {

    class func httpCommand() -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: TealiumRemoteHTTPCommandKey.commandId,
                                    description: "For processing tag-triggered HTTP requests") { response in
                let requestInfo = TealiumRemoteHTTPCommand.httpRequest(payload: response.payload())

                // TODO: Error handling?
                guard let request = requestInfo.request else {
                    return
                }

                weak var weakResponse = response
                let task = URLSession.shared.dataTask(with: request,
                                                      completionHandler: { data, urlResponse, error in
                            guard let response = weakResponse else {
                                return
                            }
                            // Legacy status reporting
                            if let err = error {
                                response.error = err
                                response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                            } else {
                                response.status = TealiumRemoteCommandStatusCode.success.rawValue
                            }
                            if data == nil {
                                response.status = TealiumRemoteCommandStatusCode.noContent.rawValue
                            }
                            if urlResponse == nil {
                                response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                            }
                            response.urlResponse = urlResponse
                            response.data = data
                            TealiumRemoteHTTPCommand.sendCompletionNotificationFor(commandId: TealiumRemoteHTTPCommandKey.commandId,
                                                                                   response: response)
                })

                task.resume()
        }
    }

    class func httpRequest(payload: [String: Any]) -> (request: URLRequest?, error: Error?) {
        guard let urlStringValue = payload[TealiumRemoteCommandsHTTPKey.url] as? String else {
            // This response is not intended for use as an HTTP command
            return (nil, TealiumRemoteCommandResponseError.missingURLTarget)
        }

        guard let method = payload[TealiumRemoteCommandsHTTPKey.method] as? String else {
            // No idea what sort of URL call we should be making
            return (nil, TealiumRemoteCommandResponseError.missingURLMethod)
        }

        var urlComponents = URLComponents(string: urlStringValue)

        if let paramsData = payload[TealiumRemoteCommandsHTTPKey.parameters] as? [String: Any] {
            let paramQueryItems = TealiumRemoteHTTPCommand.paramItemsFrom(dictionary: paramsData)
            urlComponents?.queryItems = paramQueryItems
        }

        guard let url = urlComponents?.url else {
            return (nil, TealiumRemoteCommandResponseError.couldNotConvertDataToURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let headersData = payload[TealiumRemoteCommandsHTTPKey.headers] as? [String: Any] {
            request.assignHeadersFrom(dictionary: headersData)
        }
        if let body = payload["body"] as? String {
            request.httpBody = body.data(using: .utf8)
            request.addValue("\([UInt8](body.utf8))", forHTTPHeaderField: "Content-Length")
        }
        if let body = payload["body"] as? [String: Any] {
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        if let authenticationData = payload[TealiumRemoteCommandsHTTPKey.authenticate] as? [String: Any] {
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

    /// Returns sorted queryItems from a dictionary.
    ///
    /// - Parameter dictionary: Dictionary of type [String:Any]
    /// - Returns: Sorted [URLQueryItem] array by dictionary keys
    class func paramItemsFrom(dictionary: [String: Any]) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            // Convert all values to string
            let value = String(describing: dictionary[key]!)
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        return queryItems
    }

    class func sendCompletionNotificationFor(commandId: String, response: TealiumRemoteCommandResponse) {
        guard let notification = TealiumRemoteHTTPCommand.completionNotificationFor(commandId: commandId,
                                                                                    response: response) else {
                                                                                        return
        }
        NotificationCenter.default.post(notification)
    }

    class func completionNotificationFor(commandId: String,
                                         response: TealiumRemoteCommandResponse) -> Notification? {
        guard let responseId = response.responseId() else {
            return nil
        }

        var responseStr: String
        if let responseData = response.data {
            responseStr = String(data: responseData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
        } else {
            // keep previous behavior from obj-c library
            responseStr = "(null)"
        }

        let jsString = "try { utag.mobile.remote_api.response['\(commandId)']['\(responseId)']('\(response.status)','\(responseStr)')} catch(err) {console.error(err)}"
        let notificationName = Notification.Name(rawValue: TealiumRemoteHTTPCommandKey.jsNotificationName)
        let notification = Notification(name: notificationName,
                                        object: self,
                                        userInfo: [TealiumRemoteHTTPCommandKey.jsCommand: jsString])
        return notification
    }

    override func completeWith(response: TealiumRemoteCommandResponse) {
        self.remoteCommandCompletion(response)
    }

}

public extension TealiumRemoteCommandResponse {

    func responseId() -> String? {
        guard let responseId = config()["response_id"] as? String else {
            return nil
        }
        return responseId
    }

    func body() -> String? {
        if let body = payload()["body"] as? String {
            return body
        }
        return nil
    }

}

/*
 
 ===========
 SAMPLE CALL
 ===========
 
 tealium://_http?request:{"config":{"response_id":"custom_command_12894358495341215"},"payload":{"command_id":"_http","debug":"true","url":"https://c00.adobe.com/v3/980238aa8dbbaf10a7559297f8x0ef7db78ca04841a35277573d78e64091e834/end?a_ugid=https://tags.tiqcdn.com/utag/services-test/adobe-acq-test/dev/mobile.html","method":"GET","headers":{"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36"}}}
 
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
