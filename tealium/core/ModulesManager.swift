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
    var remotePublishSettingsRetriever: TealiumPublishSettingsRetrieverProtocol?
    var collectorTypes: [Collector.Type] {
        if let optionalCollectors = config.collectors {
            return [AppDataModule.self] + optionalCollectors
        } else {
            return [AppDataModule.self,
                    DeviceDataModule.self,
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
        dataLayerManager as? SessionManagerProtocol
    }
    var logger: TealiumLoggerProtocol?
    public var modules: [TealiumModule] {
        self.collectors + self.dispatchers
    }
    var config: TealiumConfig {
        willSet {
            updateConfig(newValue)
            if newValue.isCollectEnabled == false {
                disableModule(id: ModuleNames.collect)
            }

            if newValue.isTagManagementEnabled == false {
                disableModule(id: ModuleNames.tagmanagement)
            }

            self.setupDispatchers(context: context)
            self.setupCollectors(config: newValue)
        }
    }
    private var cachedTrackData: [String: Any]?
    var context: TealiumContext

    init (_ context: TealiumContext,
          optionalCollectors: [String]? = nil,
          knownDispatchers: [String]? = nil,
          remotePublishSettingsRetriever: TealiumPublishSettingsRetrieverProtocol? = nil) {
        self.context = context
        self.originalConfig = context.config.copy
        self.config = context.config
        self.dataLayerManager = context.dataLayer
        self.connectivityManager = ConnectivityModule(context: self.context, delegate: nil, diskStorage: nil) { _, _  in
        }
        connectivityManager.addConnectivityDelegate(delegate: self)
        if self.config.shouldUseRemotePublishSettings {
            self.remotePublishSettingsRetriever = remotePublishSettingsRetriever ?? TealiumPublishSettingsRetriever(config: self.config, delegate: self)
            if let remoteConfig = self.remotePublishSettingsRetriever?.cachedSettings?.newConfig(with: self.config) {
                self.config = remoteConfig
                self.updateConfig(self.config) // Doesn't get called in the willSet
            }
        }
        self.logger = self.config.logger
        self.setupDispatchers(context: self.context) // use self.context as it might have changed for cached publish settings
        self.setupHostedDataLayer(config: self.config)
        self.setupConsentManagerModule(config: self.config)
        self.setupTimedEventScheduler()
        self.setupDispatchValidators(config: self.config)
        self.setupDispatchListeners(config: self.config)

        self.dispatchManager = DispatchManager(dispatchers: self.dispatchers,
                                               dispatchValidators: self.dispatchValidators,
                                               dispatchListeners: self.dispatchListeners,
                                               connectivityManager: self.connectivityManager,
                                               config: self.config)
        self.setupCollectors(config: self.config)
        let logRequest = TealiumLogRequest(title: ModulesManagerLogMessages.modulesManagerInitialized, messages:
                                            ["\(ModulesManagerLogMessages.collectorsInitialized): \(self.collectors.map { $0.id })",
                                             "\(ModulesManagerLogMessages.dispatchValidatorsInitialized): \(self.dispatchValidators.map { $0.id })",
                                             "\(ModulesManagerLogMessages.dispatchersInitialized): \(self.dispatchers.map { $0.id })"
                                            ], info: nil, logLevel: .info, category: .`init`)
        self.logger?.log(logRequest)
    }

    func updateConfig(_ newConfig: TealiumConfig) {
        self.dispatchManager?.config = newConfig
        self.connectivityManager.config = newConfig
        self.logger?.config = newConfig
        self.context.config = newConfig
        self.modules.forEach {
            var module = $0
            module.config = newConfig
        }
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

    func setupDispatchValidators(config: TealiumConfig) {
        config.dispatchValidators?.forEach {
            self.addDispatchValidator($0)
        }
    }

    func setupHostedDataLayer(config: TealiumConfig) {
        guard config.hostedDataLayerKeys != nil else {
            return
        }
        let hostedDataLayer = HostedDataLayer(config: config, delegate: self, diskStorage: nil) { _, _ in }
        addDispatchValidator(hostedDataLayer)
    }

    func setupConsentManagerModule(config: TealiumConfig) {
        guard config.consentPolicy != nil else {
            return
        }
        let consentManagerModule = ConsentManagerModule(context: context, delegate: self, diskStorage: nil) { _ in }
        addDispatchValidator(consentManagerModule)
    }

    func setupTimedEventScheduler() {
        let timedEventScheduler = TimedEventScheduler(context: self.context)
        self.addDispatchValidator(timedEventScheduler)
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
        guard config.isEnabled != false else { return }
        let requestData = gatherTrackData(for: request.trackDictionary)
        let newRequest = TealiumTrackRequest(data: requestData)
        dispatchManager?.processTrack(newRequest)
        cachedTrackData = newRequest.trackDictionary
    }

    func allTrackData(retrieveCachedData: Bool) -> [String: Any] {
        if retrieveCachedData, let cachedData = self.cachedTrackData {
            return cachedData
        }
        let data = gatherTrackData(for: TealiumTrackRequest(data: [:]).trackDictionary)
        var request = TealiumTrackRequest(data: data)
        _ = dispatchManager?.checkShouldQueue(request: &request)
        cachedTrackData = request.trackDictionary
        return request.trackDictionary
    }

    func gatherTrackData(for data: [String: Any]?) -> [String: Any] {
        let allData = Atomic(value: [String: Any]())
        self.collectors.forEach {
            guard let data = $0.data else {
                return
            }
            allData.value += data
        }

        allData.value[TealiumDataKey.enabledModules] = modules.sorted { $0.id < $1.id }.map { $0.id }

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

// - MARK: Collectors
extension ModulesManager {

    func addCollector(_ collector: Collector) {
        if let listener = collector as? DispatchListener {
            addDispatchListener(listener)
        }

        if let dispatchValidator = collector as? DispatchValidator {
            addDispatchValidator(dispatchValidator)
        }
        collectors.append(collector)
    }

    func setupCollectors(config: TealiumConfig) {
        guard context.config.isEnabled != false else {
            collectors.removeAll()
            return
        }
        collectorTypes.forEach { collector in
            guard !collectors.contains(where: { type(of: $0) == collector }) else {
                return
            }
            if collector == ConnectivityModule.self {
                addCollector(connectivityManager)
                return
            }

            let collector = collector.init(context: context, delegate: self, diskStorage: nil) { _, _  in }

            addCollector(collector)
        }
    }
}

// - MARK: Dispatchers
extension ModulesManager {

    func addDispatcher(_ dispatcher: Dispatcher) {
        dispatchers.append(dispatcher)
    }

    func setupDispatchers(context: TealiumContext) {
        guard context.config.isEnabled != false else {
            dispatchers.removeAll()
            return
        }
        self.config.dispatchers?.forEach { dispatcherType in
            guard !dispatchers.contains(where: { type(of: $0) == dispatcherType }) else {
                return
            }
            let config = context.config
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

            let dispatcher = dispatcherType.init(context: context, delegate: self) { result, _ in
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
