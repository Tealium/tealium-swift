//
//  ModulesManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias ModuleCompletion = (((Result<Bool, Error>, [String: Any]?)) -> Void)

enum ModulesManagerLogMessages {
    static let system = "Modules Manager"
    static let modulesManagerInitialized = "Modules Manager Initialized"
    static let collectorsInitialized = "Collectors Initialized"
    static let dispatchValidatorsInitialized = "Dispatch Validators Initialized"
    static let dispatchersInitialized = "Dispatchers Initialized"
    static let noDispatchersEnabled = "No dispatchers are enabled. Please check remote publish settings."
    static let noConnectionDispatchersDisabled = "Internet connection not available. Dispatchers could not be enabled. Will retry when connection available."
    static let connectionLost = "Internet connection lost. Events will be queued until connection restored."
}

public class ModulesManager {
    // must store a copy of the initial config to allow locally-overridden properties to take precedence over remote ones. These would otherwise be lost after the first update.
    var originalConfig: TealiumConfig
    var remotePublishSettingsRetriever: TealiumPublishSettingsRetriever?
    var collectorTypes: [Collector.Type] {
        if let optionalCollectors = config.collectors {
            return [AppDataModule.self,
                    ConsentManagerModule.self,
            ] + optionalCollectors
        } else {
            return [AppDataModule.self,
                    DeviceDataModule.self,
                    ConsentManagerModule.self,
                    ConnectivityModule.self,
            ]
        }
    }
    var collectors = [Collector]()
    var dispatchValidators = [DispatchValidator]() {
        willSet {
            dispatchManager?.dispatchValidators = newValue
        }
    }
    var dispatchManager: DispatchManagerProtocol?
    var connectivityManager: ConnectivityModule
    var dispatchers = [Dispatcher]() {
        willSet {
            self.dispatchManager?.dispatchers = newValue
        }
    }
    var dispatchListeners = [DispatchListener]() {
        willSet {
            self.dispatchManager?.dispatchListeners = newValue
        }
    }
    var dataLayerManager: DataLayerManagerProtocol?
    var sessionManager: SessionManagerProtocol? {
        get {
            dataLayerManager as? SessionManagerProtocol
        }
        // swiftlint:disable unused_setter_value
        set {

        }
        // swiftlint:enable unused_setter_value
    }
    var logger: TealiumLoggerProtocol?
    public var modules: [TealiumModule] {
        get {
            self.collectors + self.dispatchers
        }

        set {
            let modules = newValue
            dispatchers = []
            collectors = []
            modules.forEach {
                switch $0 {
                case let module as Dispatcher:
                    addDispatcher(module)
                case let module as Collector:
                    addCollector(module)
                default:
                    return
                }
            }
        }
    }
    var config: TealiumConfig {
        willSet {
            self.dispatchManager?.config = newValue
            self.connectivityManager.config = newValue
            self.logger?.config = newValue
            self.updateConfig(config: newValue)
            self.modules.forEach {
                var module = $0
                module.config = newValue
            }
        }
    }

    var context: TealiumContext

    init (_ context: TealiumContext,
          optionalCollectors: [String]? = nil,
          knownDispatchers: [String]? = nil) {
        self.context = context
        self.originalConfig = context.config.copy
        self.config = context.config
        self.dataLayerManager = context.dataLayer
        self.connectivityManager = ConnectivityModule(context: self.context, delegate: nil, diskStorage: nil) { _, _  in
        }
        connectivityManager.addConnectivityDelegate(delegate: self)
        if self.config.shouldUseRemotePublishSettings {
            self.remotePublishSettingsRetriever = TealiumPublishSettingsRetriever(config: self.config, delegate: self)
            if let remoteConfig = self.remotePublishSettingsRetriever?.cachedSettings?.newConfig(with: self.config) {
                self.config = remoteConfig
            }
        }
        self.logger = self.config.logger
        self.setupDispatchers(config: self.config)
        self.setupHostedDataLayer(config: self.config)
        self.setupDispatchValidators(config: self.config)
        self.setupDispatchListeners(config: self.config)

        self.dispatchManager = DispatchManager(dispatchers: self.dispatchers,
                                               dispatchValidators: self.dispatchValidators,
                                               dispatchListeners: self.dispatchListeners,
                                               connectivityManager: self.connectivityManager,
                                               config: self.config)
        self.setupCollectors(config: self.config)
        TealiumQueues.backgroundSerialQueue.async {
            let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.modulesManagerInitialized, messages:
                                                ["\(ModulesManagerLogMessages.collectorsInitialized): \(self.collectors.map { $0.id })",
                                                 "\(ModulesManagerLogMessages.dispatchValidatorsInitialized): \(self.dispatchValidators.map { $0.id })",
                                                 "\(ModulesManagerLogMessages.dispatchersInitialized): \(self.dispatchers.map { $0.id })"
                                                ], info: nil, logLevel: .info, category: .`init`)
            self.logger?.log(logRequest)
        }
    }

    func updateConfig(config: TealiumConfig) {
        if config.isCollectEnabled == false {
            disableModule(id: ModuleNames.collect)
        }

        if config.isTagManagementEnabled == false {
            disableModule(id: ModuleNames.tagmanagement)
        }

        self.setupDispatchers(config: config)
    }

    func addCollector(_ collector: Collector) {
        if let listener = collector as? DispatchListener {
            addDispatchListener(listener)
        }

        if let dispatchValidator = collector as? DispatchValidator {
            addDispatchValidator(dispatchValidator)
        }

        guard collectors.first(where: {
            type(of: $0) == type(of: collector)
        }) == nil else {
            return
        }
        collectors.append(collector)
    }

    func addDispatchListener(_ listener: DispatchListener) {
        guard dispatchListeners.first(where: {
            type(of: $0) == type(of: listener)
        }) == nil else {
            return
        }
        dispatchListeners.append(listener)
    }

    func addDispatchValidator(_ validator: DispatchValidator) {
        guard dispatchValidators.first(where: {
            type(of: $0) == type(of: validator)
        }) == nil else {
            return
        }
        dispatchValidators.append(validator)
    }

    func addDispatcher(_ dispatcher: Dispatcher) {
        guard dispatchers.first(where: {
            type(of: $0) == type(of: dispatcher)
        }) == nil else {
            return
        }
        dispatchers.append(dispatcher)
    }

    func setupCollectors(config: TealiumConfig) {
        collectorTypes.forEach { collector in
            if collector == ConsentManagerModule.self && config.consentPolicy == nil {
                return
            }

            if collector == ConnectivityModule.self {
                addCollector(connectivityManager)
                return
            }

            let collector = collector.init(context: context, delegate: self, diskStorage: nil) { _, _  in

            }

            addCollector(collector)
        }
    }

    func setupDispatchers(config: TealiumConfig) {
        self.config.dispatchers?.forEach { dispatcherType in
            let dispatcherTypeDescription = String(describing: dispatcherType)

            if dispatcherTypeDescription.contains(ModuleNames.tagmanagement) {
                if config.isTagManagementEnabled == false {
                    return
                }
                self.sessionManager?.isTagManagementEnabled = true
            }

            if dispatcherTypeDescription.contains(ModuleNames.collect),
               config.isCollectEnabled == false {
                return
            }

            let dispatcher = dispatcherType.init(config: config, delegate: self) { result, _ in
                switch result {
                case .failure:
                    print("log error")
                default:
                    break
                }
            }

            self.addDispatcher(dispatcher)
        }
        if self.dispatchers.isEmpty {
            let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.system,
                                               message: ModulesManagerLogMessages.noDispatchersEnabled,
                                               info: nil,
                                               logLevel: .error,
                                               category: .`init`)
            self.logger?.log(logRequest)
        }

    }

    func setupDispatchValidators(config: TealiumConfig) {
        config.dispatchValidators?.forEach {
            self.addDispatchValidator($0)
        }
    }

    func setupHostedDataLayer(config: TealiumConfig) {
        if config.hostedDataLayerKeys != nil {
            let hostedDataLayer = HostedDataLayer(config: config, delegate: self, diskStorage: nil) { _, _ in }
            addDispatchValidator(hostedDataLayer)
        }
    }

    func setupDispatchListeners(config: TealiumConfig) {
        config.dispatchListeners?.forEach {
            self.addDispatchListener($0)
        }
    }

    func sendTrack(_ request: TealiumTrackRequest) {
        if self.config.shouldUseRemotePublishSettings == true {
            self.remotePublishSettingsRetriever?.refresh()
        }
        let requestData = gatherTrackData(for: request.trackDictionary)
        let newRequest = TealiumTrackRequest(data: requestData)
        dispatchManager?.processTrack(newRequest)
    }

    func gatherTrackData(for data: [String: Any]?) -> [String: Any] {
        let allData = Atomic(value: [String: Any]())
        self.collectors.forEach {
            guard let data = $0.data else {
                return
            }
            allData.value += data
        }

        allData.value[TealiumKey.enabledModules] = modules.sorted { $0.id < $1.id }.map { $0.id }

        sessionManager?.refreshSession()
        if let dataLayer = dataLayerManager?.all {
            allData.value += dataLayer
        }

        if let data = data {
            allData.value += data
        }
        return allData.value
    }

    func disableModule(id: String) {
        if let module = modules.first(where: { $0.id == id }) {
            switch module {
            case let module as Collector:
                self.collectors = self.collectors.filter { type(of: module) != type(of: $0) }
            case let module as Dispatcher:
                self.dispatchers = self.dispatchers.filter { type(of: module) != type(of: $0) }
            default:
                return
            }
        }
    }

    deinit {
        connectivityManager.removeAllConnectivityDelegates()
    }

}

extension ModulesManager: ModuleDelegate {
    public func requestTrack(_ track: TealiumTrackRequest) {
        TealiumQueues.backgroundSerialQueue.async {
            self.sendTrack(track)
        }
    }

    public func requestDequeue(reason: String) {
        self.dispatchManager?.handleDequeueRequest(reason: reason)
    }

    public func processRemoteCommandRequest(_ request: TealiumRequest) {
        self.dispatchers.forEach {
            $0.dynamicTrack(request, completion: nil)
        }
    }
}

extension ModulesManager: ConnectivityDelegate {
    public func connectionLost() {
        logger?.log(TealiumLogRequest(title: ModulesManagerLogMessages.system, message: ModulesManagerLogMessages.connectionLost, info: nil, logLevel: .info, category: .general))
    }

    public func connectionRestored() {
        TealiumQueues.backgroundSerialQueue.async {
            self.requestDequeue(reason: TealiumValue.connectionRestoredReason)
        }
    }

}

extension ModulesManager: TealiumPublishSettingsDelegate {
    func didUpdate(_ publishSettings: RemotePublishSettings) {
        let newConfig = publishSettings.newConfig(with: self.originalConfig)
        if newConfig != self.config {
            self.config = newConfig
        }
    }
}
