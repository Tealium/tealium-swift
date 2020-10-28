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

    weak var queue = TealiumQueues.backgroundSerialQueue
    public var jsonCommands = [RemoteCommandProtocol]()
    public var webviewCommands = [RemoteCommandProtocol]()
    weak public var moduleDelegate: ModuleDelegate?
    static var pendingResponses = Atomic<[String: Bool]>(value: [String: Bool]())
    var urlSession: URLSessionProtocol?
    var diskStorage: TealiumDiskStorageProtocol?
    var config: TealiumConfig
    var hasFetched = false
    var isFirstFetch = true
    var logger: TealiumLoggerProtocol?

    public init(config: TealiumConfig,
                delegate: ModuleDelegate?,
                urlSession: URLSessionProtocol = URLSession.shared,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.config = config
        self.logger = config.logger
        self.urlSession = urlSession
        moduleDelegate = delegate
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: RemoteCommandsKey.moduleName)
    }

    /// Fetches and updates the  JSON `RemoteCommandConfig` then saves to PersistentData storage for processing
    /// - Parameters:
    ///   - command: `TealiumRemoteCommandConfigProtocol` The current command in process
    ///   - path: `(url: URL, file: String)` `URL` to the remote command config and `String` filename of the remote command
    public func refresh(_ command: RemoteCommandProtocol, url: URL, file: String) {
        if !hasFetched || self.jsonCommands.count == 0 {
            retrieveAndSave(command, url: url, file: file)
        }
        guard let commandConfig = command.config, let lastFetch = commandConfig.lastFetch,
              let date = lastFetch.addSeconds(config.remoteCommandConfigRefresh.interval),
              Date() > date else {
            return
        }
        retrieveAndSave(command, url: url, file: file)
    }

    /// Updates the `RemoteCommandConfig`URL and filename  that is currently being processed
    /// - Parameters:
    ///   - command: `inout TealiumRemoteCommandProtocol` The current command in process
    ///   - path: `(url: URL, file: String)` `URL` to the remote command config and `String` filename of the remote command
    func update(command: inout RemoteCommandProtocol,
                url: URL, file: String) {
        command.config?.commandURL = url
        command.config?.fileName = file
    }

    /// Gets the `RemoteCommandConfig` from a remote location. If the contents have been modified since last fetch, data will be returned, otherwise `nil` will be the result.
    /// - Parameters:
    ///   - url: `URL` to the JSON remote command config
    ///   - lastFetch: `Date` when the remote command config was last fetched
    ///   - completion: `(Result<RemoteCommandConfig, Error>) -> Void` The new config retrieved, or `RemoteCommandError` if it has not been modified since last fetch
    func remoteCommandConfig(from url: URL, isFirstFetch: Bool, lastFetch: Date, completion: @escaping (Result<RemoteCommandConfig, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !isFirstFetch {
            request.setValue(lastFetch.httpIfModifiedHeader, forHTTPHeaderField: "If-Modified-Since")
        }
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.urlSession?.tealiumDataTask(with: request) { data, response, _ in
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(TealiumRemoteCommandsError.noResponse))
                return
            }
            self.isFirstFetch = false
            switch HttpStatusCodes(rawValue: response.statusCode) {
            case .ok:
                guard let commandConfig = self.config(from: data!) else {
                    completion(.failure(TealiumRemoteCommandsError.couldNotDecodeJSON))
                    return
                }
                completion(.success(commandConfig))
            case .notModified:
                completion(.failure(TealiumRemoteCommandsError.notModified))
            default:
                completion(.failure(TealiumRemoteCommandsError.invalidResponse))
                return
            }
        }.resume()
    }

    /// Decodes the `RemoteCommandConfig` data
    /// - Parameter data: `RemoteCommandConfig`
    public func config(from data: Data) -> RemoteCommandConfig? {
        return try? JSONDecoder().decode(RemoteCommandConfig.self, from: data)
    }

    /// Saves the `RemoteCommandConfig` to PersistendData
    /// - Parameters:
    ///   - data: `RemoteCommandConfig`
    ///   - key: `String` file name of the JSON remote command
    func save(_ data: RemoteCommandConfig, for key: String) {
        diskStorage?.save(data, fileName: key, completion: nil)
    }

    /// Gets the latest `RemoteCommandConfig` and saves to PersistentData storage
    /// - Parameters:
    ///   - command: `TealiumRemoteCommandProtocol`
    ///   - path: `(url: URL, file: String)` `URL` to the remote command config and `String` filename of the remote command
    public func retrieveAndSave(_ command: RemoteCommandProtocol, url: URL, file: String) {
        hasFetched = true
        var command = command
        remoteCommandConfig(from: url, isFirstFetch: isFirstFetch, lastFetch: command.config?.lastFetch ?? Date()) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let config):
                self.remove(jsonCommand: file)
                command.config = config
                self.update(command: &command, url: url, file: file)
                self.save(config, for: file)
                self.jsonCommands.append(command)
            case .failure(let error):
                self.log(error)
            }
        }
    }

    /// Gets the current `RemoteCommandConfig` from PersistentData storage
    /// - Parameter key: `String` filename to the remote command
    func cachedConfig(for key: String) -> RemoteCommandConfig? {
        let config = self.diskStorage?.retrieve(key,
                                                as: RemoteCommandConfig.self)
        return config
    }

    /// Returns tealium url prefix including account and profile
    var tealiumURLPrefix: String {
        "\(RemoteCommandsKey.dlePrefix)\(config.account)/\(config.profile)/"
    }

    /// Adds a remote command for later execution.
    ///
    /// - Parameter remoteCommand: `TealiumRemoteCommand` to be added for later execution
    // swiftlint:disable pattern_matching_keywords
    public func add(_ remoteCommand: RemoteCommandProtocol) {
        var remoteCommand = remoteCommand
        remoteCommand.delegate = self
        switch remoteCommand.type {
        case .local(let file, let bundle):
            if let localConfig = RemoteCommandConfig(file: file, logger, bundle) {
                remoteCommand.config = localConfig
                jsonCommands.append(remoteCommand)
            }
        case .remote(let urlString):
            guard let url = URL(string: urlString.cacheBuster) else {
                return
            }
            if let localConfig = RemoteCommandConfig(file: urlString.fileName, logger, nil) {
                remoteCommand.config = localConfig
                remove(jsonCommand: urlString.fileName)
                update(command: &remoteCommand, url: url, file: urlString.fileName)
                jsonCommands.append(remoteCommand)
            }
            remoteCommand.config = cachedConfig(for: urlString.fileName)
            remove(jsonCommand: urlString.fileName)
            update(command: &remoteCommand, url: url, file: urlString.fileName)
            refresh(remoteCommand, url: url, file: urlString.fileName)
        case .webview:
            webviewCommands.append(remoteCommand)
        }
    }
    // swiftlint:enable pattern_matching_keywords

    /// Removes a `TealiumRemoteCommand` so it can no longer be called.
    ///
    /// - Parameter commandWithId: `String` containing the command ID to be removed
    public func remove(commandWithId: String) {
        jsonCommands = jsonCommands.filter { $0.commandId != commandWithId }
        webviewCommands = webviewCommands.filter { $0.commandId != commandWithId }
    }

    /// Removes a JSON `TealiumRemoteCommand` so it can no longer be called.
    ///
    /// - Parameter jsonCommand: `String` containing the file name to be removed
    public func remove(jsonCommand name: String) {
        jsonCommands = jsonCommands.filter { $0.config?.fileName != name }
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
            guard let request = data[TealiumKey.tagmanagementNotification] as? URLRequest else {
                return
            }
            triggerCommand(from: request)
        case .JSON:
            jsonCommands.forEach { command in
                guard let config = command.config else {
                    return
                }
                guard let payload = data[RemoteCommandsKey.payload] as? [String: Any] else {
                    command.complete(with: data, config: config, completion: completion)
                    return
                }
                command.complete(with: payload, config: config, completion: completion)
            }
        }

    }

    /// Trigger an associated remote command from a url request.
    ///￼
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

    private func log(_ error: Error) {
        guard error.localizedDescription != "notModified" else {
            let request = TealiumLogRequest(title: "Remote Command", message: "Config not updated because JSON was not modified", info: nil, logLevel: .info, category: .general)
            logger?.log(request)
            return
        }
        let request = TealiumLogRequest(title: "Remote Commands",
                                        message: "Error while processing the remote command configuration: \(error.localizedDescription)",
                                        info: nil,
                                        logLevel: .error,
                                        category: .general)
        logger?.log(request)
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
#endif
