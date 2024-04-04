//
//  RemoteCommandsManager.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

/// Manages instances of TealiumRemoteCommand
public class RemoteCommandsManager: NSObject, RemoteCommandsManagerProtocol {
    public typealias Resource = RemoteCommandConfig
    weak var queue = TealiumQueues.backgroundSerialQueue

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject<[RemoteCommandProtocol]>())
    public var onCommandsChanged: TealiumObservable

    public private(set) var jsonCommands = [RemoteCommandProtocol]() {
        didSet {
            _onCommandsChanged.publish(jsonCommands + webviewCommands)
        }
    }
    public private(set) var webviewCommands = [RemoteCommandProtocol]() {
        didSet {
            _onCommandsChanged.publish(jsonCommands + webviewCommands)
        }
    }
    weak public var moduleDelegate: ModuleDelegate?
    static var pendingResponses = Atomic<[String: Bool]>(value: [String: Bool]())
    public let urlSession: URLSessionProtocol
    var diskStorage: TealiumDiskStorageProtocol
    let config: TealiumConfig
    let logger: TealiumLoggerProtocol?
    var commandsRefreshers = [String: ResourceRefresher<RemoteCommandConfig>]()
    let resourceRetriever: ResourceRetriever<RemoteCommandConfig>
    public init(config: TealiumConfig,
                delegate: ModuleDelegate?,
                urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.config = config
        self.logger = config.logger
        self.urlSession = urlSession
        moduleDelegate = delegate
        let diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: RemoteCommandsKey.moduleName)
        self.diskStorage = diskStorage
        resourceRetriever = ResourceRetriever(urlSession: urlSession, resourceBuilder: Self.config(from:etag:))
    }

    /// Fetches and updates the  JSON `RemoteCommandConfig` then saves to PersistentData storage for processing
    /// - Parameters:
    ///   - command: `TealiumRemoteCommandConfigProtocol` The current command in process
    ///   - path: `(url: URL, file: String)` `URL` to the remote command config and `String` filename of the remote command
    public func refresh(_ command: RemoteCommandProtocol) {
        commandsRefreshers[command.commandId]?.requestRefresh()
    }

    /// Decodes the `RemoteCommandConfig` data
    /// - Parameter data: `RemoteCommandConfig`
    static public func config(from data: Data, etag: String?) -> RemoteCommandConfig? {
        var config = try? JSONDecoder().decode(RemoteCommandConfig.self, from: data)
        config?.etag = etag
        return config
    }

    private func isCommandAdded(_ commandId: String) -> Bool {
        return jsonCommands.contains { $0.commandId == commandId }
            || webviewCommands.contains { $0.commandId == commandId }
    }

    /// Adds a remote command for later execution.
    ///
    /// If a command with the same commandId has already been added the new one will be ignored.
    ///
    /// - Parameter remoteCommand: `TealiumRemoteCommand` to be added for later execution
    public func add(_ remoteCommand: RemoteCommandProtocol) {
        guard !isCommandAdded(remoteCommand.commandId) else {
            return
        }
        var remoteCommand = remoteCommand
        remoteCommand.delegate = self
        switch remoteCommand.type {
        case let .local(file, bundle):
            if let localConfig = RemoteCommandConfig(file: file, logger, bundle) {
                remoteCommand.config = localConfig
                remove(jsonCommand: remoteCommand.commandId)
                jsonCommands.append(remoteCommand)
            } else {
                let request = TealiumLogRequest(title: "Remote Commands",
                                                message: "Could not find a valid local JSON command named \(file)",
                                                info: nil,
                                                logLevel: .error,
                                                category: .general)
                config.logger?.log(request)
            }
        case .remote(let urlString):
            jsonCommands.append(remoteCommand)
            guard let url = URL(string: urlString.cacheBuster) else {
                return
            }
            let fileName = getConfigFilename(forUrl: urlString, commandId: remoteCommand.commandId)
            let parameters = RefreshParameters<RemoteCommandConfig>(id: remoteCommand.commandId,
                                                                    url: url,
                                                                    fileName: fileName,
                                                                    refreshInterval: config.remoteCommandConfigRefresh.interval,
                                                                    errorCooldownInterval: 30)
            let refresher = ResourceRefresher(resourceRetriever: resourceRetriever,
                                              diskStorage: diskStorage,
                                              refreshParameters: parameters)
            commandsRefreshers[remoteCommand.commandId] = refresher
            refresher.delegate = self
            let configCacheFound = remoteCommand.config != nil
            if !configCacheFound,
                let defaultConfig = RemoteCommandConfig(file: fileName, logger, nil) {
                remoteCommand.config = defaultConfig
            }
            refresher.requestRefresh()
        case .webview:
            webviewCommands.append(remoteCommand)
        }
    }

    private func getConfigFilename(forUrl url: String, commandId: String) -> String {
        // check if Tealium DLE URL
        if url.contains("\(TealiumValue.tealiumDleBaseURL)\(config.account)/\(config.profile)") {
            return url.fileName
        }
        return commandId
    }

    /// Removes a `TealiumRemoteCommand` so it can no longer be called.
    ///
    /// - Parameter commandWithId: `String` containing the command ID to be removed
    public func remove(commandWithId commandId: String) {
        remove(jsonCommand: commandId)
        webviewCommands = webviewCommands.filter { $0.commandId != commandId }
    }

    /// Removes a JSON `TealiumRemoteCommand` so it can no longer be called.
    ///
    /// - Parameter jsonCommand: `String` containing the commandId to be removed
    public func remove(jsonCommand commandId: String) {
        jsonCommands = jsonCommands.filter { $0.commandId != commandId }
    }

    /// Removes all previously-added Remote Commands so they can no longer be executed.
    public func removeAll() {
        jsonCommands.removeAll()
        webviewCommands.removeAll()
    }

    /// Triggers all JSON and WebView Remote Commands that have been added
    /// - Parameter type: `RemoteCommandType` either webview, local, or remote file
    /// - Parameter data: `[String: Any]` payload that has been sent in a tracking call
    public func trigger(command type: SimpleCommandType, with data: [String: Any], completion: ModuleCompletion?) {
        switch type {
        case .webview:
            guard let request = data[TealiumDataKey.tagmanagementNotification] as? URLRequest else {
                return
            }
            triggerCommand(from: request)
        case .JSON:
            jsonCommands.forEach { command in
                guard let config = command.config else {
                    return
                }
                command.complete(with: getPayloadData(data: data),
                                 config: config,
                                 completion: completion)
            }
        }
    }

    func getPayloadData(data: [String: Any]) -> [String: Any] {
        guard var payload = data[RemoteCommandsKey.payload] as? [String: Any] else {
            return data
        }
        let key = TealiumDataKey.eventType
        if let eventType = data[key] {
            payload += [key: eventType]
        }
        return payload
    }

    /// Trigger an associated remote command from a url request.
    /// ￼
    /// - Parameter request: `URLRequest` to check for a remote command.
    /// - Returns: `TealiumRemoteCommandsError` if unable to trigger a remote command. If nil is returned,
    ///     then call was a successfully triggered remote command.
    @discardableResult
    public func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError? {
        if request.url?.scheme != TealiumKey.tealiumURLScheme {
            return TealiumRemoteCommandsError.invalidScheme
        }
        guard let commandId = request.url?.host else {
            return TealiumRemoteCommandsError.commandIdNotFound
        }
        guard let command = webviewCommands[commandId] else {
            return TealiumRemoteCommandsError.commandNotFound
        }
        guard let response = RemoteCommandResponse(request: request) else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        if let responseId = response.responseId {
            RemoteCommandsManager.pendingResponses.value[responseId] = true
        }
        command.completeWith(response: response)
        return nil
    }

    deinit {
        urlSession.finishTealiumTasksAndInvalidate()
    }
}

extension RemoteCommandsManager: RemoteCommandDelegate {

    /// Triggers the completion block registered for a specific remote command.
    ///
    /// - Parameters:
    ///     - command: `TealiumRemoteCommand` to be executed
    ///     - response: `RemoteCommandResponse` object passed back from TiQ.
    ///     If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///     it must set the "hasCustomCompletionHandler" flag, otherwise the remote command response
    ///     will be sent automatically
    public func remoteCommandRequestsExecution(_ command: RemoteCommandProtocol,
                                               response: RemoteCommandResponseProtocol) {
        self.queue?.async {
            command.completion(response)
            if !response.hasCustomCompletionHandler {
                RemoteCommand.sendRemoteCommandResponse(for: command.commandId,
                                                        response: response,
                                                        delegate: self.moduleDelegate)
            }
        }
    }
}

extension RemoteCommandsManager: ResourceRefresherDelegate {
    public func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didLoad resource: RemoteCommandConfig) {
        guard let index = jsonCommands.firstIndex(where: { $0.commandId == refresher.id }) else {
            return
        }
        jsonCommands[index].config = resource
    }

    public func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didFailToLoadResource error: Error) {
        guard error.localizedDescription != "notModified" else {
            let request = TealiumLogRequest(title: "Remote Command", message: "Config not updated because JSON was not modified", info: nil, logLevel: .info, category: .general)
            config.logger?.log(request)
            return
        }
        let request = TealiumLogRequest(title: "Remote Commands",
                                        message: "Error while processing the remote command configuration: \(error.localizedDescription)",
                                        info: nil,
                                        logLevel: .error,
                                        category: .general)
        config.logger?.log(request)
    }
}
#endif
