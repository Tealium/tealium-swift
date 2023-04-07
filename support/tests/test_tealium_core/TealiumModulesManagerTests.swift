//
//  TealiumModulesManagerTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
#if os(iOS)
@testable import TealiumTagManagement
#endif
import XCTest

var defaultTealiumConfig: TealiumConfig { TealiumConfig(account: "tealiummobile",
                                                        profile: "demo",
                                                        environment: "dev",
                                                        options: nil)
}
let config = testTealiumConfig
class TealiumModulesManagerTests: XCTestCase {
    lazy var context = TestTealiumHelper.context(with: config)
    var modulesManager: ModulesManager {
        let config = context.config
        config.shouldUseRemotePublishSettings = false
        #if os(iOS)
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.Collect]
        #else
        config.dispatchers = [Dispatchers.Collect]
        #endif
        config.logLevel = TealiumLogLevel.error
        config.loggerType = .print
        return getModulesManager(context, remotePublishSettingsRetriever: nil)
    }
    
    func getModulesManager(_ context: TealiumContext, remotePublishSettingsRetriever retriever: TealiumPublishSettingsRetrieverProtocol?) -> ModulesManager {
        let modulesManager = ModulesManager(context, remotePublishSettingsRetriever: retriever)
        modulesManager.connectionRestored()
        modulesManager.dispatchValidators.removeAll() // TimedEvents crashes due to context.config being unowed
        return modulesManager
    }

    func modulesManagerForConfig(config: TealiumConfig) -> ModulesManager {
        let context = TestTealiumHelper.context(with: config)
        return ModulesManager(context)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        TealiumExpectations.expectations = [:]
    }

    func testAddCollector() {
        let config = testTealiumConfig.copy
        config.collectors = [DummyCollector.self, DummyCollector.self]
        let context = TestTealiumHelper.context(with: config, dataLayer: DummyDataManagerNoData())
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = ModulesManager(context)
            
            XCTAssertTrue(modulesManager.collectors.contains(where: { $0.id == "Dummy" }))
            
            XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { type(of: $0) == DummyCollector.self }))
            XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { type(of: $0) == DummyCollector.self }))
            
            XCTAssertEqual(modulesManager.collectors.filter{ $0.id == "Dummy" }.count, 1)
            XCTAssertEqual(modulesManager.dispatchListeners.filter{ type(of:$0) == DummyCollector.self }.count, 1)
            XCTAssertEqual(modulesManager.dispatchValidators.filter{ $0.id == "Dummy" }.count, 1)
        }
    }

    func testDisableModule() {
        let context = TestTealiumHelper.context(with: testTealiumConfig, dataLayer: DummyDataManagerNoData())
        let collector = DummyCollector(context: context, delegate: self, diskStorage: nil) { _, _ in

        }
        let dispatcher = DummyDispatcher(context: context, delegate: self) { _ in

        }
        let modulesManager = ModulesManager(context)

        modulesManager.collectors = [collector]
        modulesManager.dispatchers = [dispatcher]
        XCTAssertEqual(modulesManager.collectors.count, 1)
        modulesManager.disableModule(id: "Dummy")
        XCTAssertEqual(modulesManager.collectors.count, 0)
        XCTAssertEqual(modulesManager.dispatchers.count, 1)
        modulesManager.disableModule(id: "DummyDispatcher")
        XCTAssertEqual(modulesManager.dispatchers.count, 0)

    }

    func testConnectionRestored() {
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()

        XCTAssertEqual(modulesManager.dispatchers.count, 0)

        modulesManager.connectionRestored()

        #if os(iOS)
        XCTAssertEqual(modulesManager.dispatchers.count, 0)
        #else
        XCTAssertEqual(modulesManager.dispatchers.count, 0)
        #endif
    }

    func testSendTrack() {
        TealiumExpectations.expectations["sendTrack"] = expectation(description: "sendTrack")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(context: modulesManager.context, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerSendTrack(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)

        let track = TealiumTrackRequest(data: [:])
        modulesManager.sendTrack(track)
        wait(for: [TealiumExpectations.expectations["sendTrack"]!], timeout: 1.0)
    }

    func testRequestTrack() {
        TealiumExpectations.expectations["requestTrack"] = expectation(description: "requestTrack")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(context: modulesManager.context, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerRequestTrack(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)

        let track = TealiumTrackRequest(data: [:])
        modulesManager.sendTrack(track)
        wait(for: [TealiumExpectations.expectations["requestTrack"]!], timeout: 1.0)
    }

    func testDequeue() {
        let expect = expectation(description: "dequeue")
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dispatchers = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let connectivity = ConnectivityModule(context: modulesManager.context, delegate: nil, diskStorage: nil) { _ in }
        let dummyDequeue = DummyDispatchManagerdequeue(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)
        dummyDequeue.asyncExpectation = expect
        modulesManager.dispatchManager = dummyDequeue
        modulesManager.requestDequeue(reason: "test")
        wait(for: [expect], timeout: 1.0)
    }

    func testSetupDispatchListeners() {
        let modulesManager = self.modulesManager
        let collector = DummyCollector(context: modulesManager.context, delegate: self, diskStorage: nil) { _, _ in

        }
        modulesManager.collectors = []
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let config = testTealiumConfig
        config.dispatchListeners = [collector]
        modulesManager.setupDispatchListeners(config: config)
        XCTAssertEqual(modulesManager.dispatchListeners.count, 1)
        XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { ($0 as! Collector).id == "Dummy" }))
    }

    func testSetupDispatchValidators() {
        let modulesManager = self.modulesManager
        let collector = DummyCollector(context: modulesManager.context, delegate: self, diskStorage: nil) { _, _ in

        }

        modulesManager.collectors = []
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let config = testTealiumConfig
        config.dispatchValidators = [collector]
        modulesManager.setupDispatchValidators(config: config)
        XCTAssertEqual(modulesManager.dispatchValidators.count, 1)
        XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { ($0 as! Collector).id == "Dummy" }))
    }

    func testConfigPropertyUpdate() {
        let collector = DummyCollector(context: self.modulesManager.context, delegate: self, diskStorage: nil) { _, _  in

        }
        TealiumExpectations.expectations["configPropertyUpdate"] = expectation(description: "configPropertyUpdate")
        TealiumExpectations.expectations["configPropertyUpdateModule"] = expectation(description: "configPropertyUpdateModule")
        let modulesManager = self.modulesManager

        modulesManager.collectors = [collector]
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        let connectivity = ConnectivityModule(context: self.modulesManager.context, delegate: nil, diskStorage: nil) { _ in }
        modulesManager.dispatchManager = DummyDispatchManagerConfigUpdate(dispatchers: nil, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: testTealiumConfig)
        let config = testTealiumConfig
        config.logLevel = .info
        modulesManager.config = config
        XCTAssertEqual(modulesManager.config, modulesManager.dispatchManager!.config)
        if let configPropertyUpdateModule = TealiumExpectations.expectations["configPropertyUpdateModule"] {
            if let configPropertyUpdate = TealiumExpectations.expectations["configPropertyUpdate"] {
                wait(for: [configPropertyUpdate, configPropertyUpdateModule], timeout: 1.0)
            } else {
                wait(for: [configPropertyUpdateModule], timeout: 1.0)
            }
            return
        } else if let configPropertyUpdate = TealiumExpectations.expectations["configPropertyUpdate"] {
            wait(for: [configPropertyUpdate], timeout: 1.0)
        }
    }

    func testSetModules() {
        let context = TestTealiumHelper.context(with: testTealiumConfig, dataLayer: DummyDataManagerNoData())
        let collector = DummyCollector(context: context, delegate: self, diskStorage: nil) { _, _  in

        }
        let modulesManager = ModulesManager(context)
        modulesManager.dispatchListeners = []
        modulesManager.dispatchValidators = []
        modulesManager.dispatchers = []
        modulesManager.collectors = [collector]
        XCTAssertEqual(modulesManager.modules.count, modulesManager.collectors.count)
    }

    func testDispatchValidatorAddedFromConfig() {
        let validator = DummyCollector(context: self.modulesManager.context, delegate: self, diskStorage: nil) { _, _  in

        }
        let config = testTealiumConfig
        config.dispatchValidators = [validator]
        let modulesManager = self.modulesManagerForConfig(config: config)
        XCTAssertTrue(modulesManager.dispatchValidators.contains(where: { $0.id == "Dummy" }))
    }

    func testDispatchListenerAddedFromConfig() {
        let listener = DummyCollector(context: self.modulesManager.context, delegate: self, diskStorage: nil) { _, _  in

        }
        let config = testTealiumConfig
        config.dispatchListeners = [listener]
        let modulesManager = self.modulesManagerForConfig(config: config)
        XCTAssertTrue(modulesManager.dispatchListeners.contains(where: { ($0 as! DispatchValidator).id == "Dummy" }))
    }

    func testGatherTrackData() {
        let context = TestTealiumHelper.context(with: testTealiumConfig, dataLayer: DummyDataManagerNoData())
        let modulesManager = ModulesManager(context)
        modulesManager.collectors = []
        let collector = DummyCollector(context: context, delegate: self, diskStorage: nil) { _, _  in

        }
        modulesManager.addCollector(collector)
        var data = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        data["enabled_modules"] = nil
        XCTAssertEqual(["testGatherTrackData": true, "dummy": true], data as! [String: Bool])
        modulesManager.dataLayerManager = DummyDataManager()
        var dataWithEventData = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        dataWithEventData["enabled_modules"] = nil
        XCTAssertEqual(["testGatherTrackData": true, "dummy": true, "eventData": true, "sessionData": true], dataWithEventData as! [String: Bool])
    }

    func testGatherTrackDataWithModulesList() {
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dataLayerManager = DummyDataManagerNoData()
        let collector = DummyCollector(context: modulesManager.context, delegate: self, diskStorage: nil) { _, _  in

        }
        modulesManager.addCollector(collector)
        let data = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        XCTAssertNotNil(data["enabled_modules"]!)
        #if os(iOS)
        XCTAssertEqual(["Collect", "Dummy", "TagManagement"], data["enabled_modules"] as! [String])
        #else
        XCTAssertEqual(["Collect", "Dummy"], data["enabled_modules"] as! [String])
        #endif
        modulesManager.dataLayerManager = DummyDataManager()
        let dataWithEventData = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        XCTAssertNotNil(dataWithEventData["enabled_modules"]!)
    }

    func testGatherTrackDataAfterMigratingLegacyData() {
        let migratedData = MockMigratedDataLayer()
        let modulesManager = self.modulesManager
        modulesManager.dataLayerManager = migratedData
        let data = modulesManager.gatherTrackData(for: ["testGatherTrackData": true])
        XCTAssertEqual(data["custom_persistent_key"] as! String, "customValue")
        XCTAssertNotNil(data["migrated_lifecycle"] as! [String: Any])
        XCTAssertEqual(data["consent_status"] as! Int, 1)
    }
    
    func testAllTrackData() {
        let modulesManager = self.modulesManager
        modulesManager.collectors = []
        modulesManager.dataLayerManager = DummyDataManager()
        let collector = DummyCollector(context: modulesManager.context, delegate: self, diskStorage: nil) { _, _  in
        }
        modulesManager.addCollector(collector)
        let data = modulesManager.allTrackData(retrieveCachedData: false)
        XCTAssertNotNil(data["enabled_modules"]!)
        XCTAssertNotNil(data["dummy"])
        XCTAssertNotNil(data["dummyQueue"])
        XCTAssertNotNil(data["sessionData"])
        
        let cachedData = modulesManager.allTrackData(retrieveCachedData: true)
        XCTAssertTrue(data.equal(to: cachedData))
        
        modulesManager.sendTrack(TealiumTrackRequest(data: ["tealium_event": "someValue"]))
        
        let newCachedData = modulesManager.allTrackData(retrieveCachedData: true)
        XCTAssertEqual(newCachedData["tealium_event"] as? String, "someValue")
    }
    
    func testPropagatesConfigUpdatesOnPublishSettingsCache() {
        let defaultSettings = RemotePublishSettings()
        let retriever = MockPublishSettingsRetriever(cachedSettings: defaultSettings)
        let config = context.config
        config.shouldUseRemotePublishSettings = true
        context.config.dispatchers = [Dispatchers.Collect]
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let collect = modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})
            XCTAssertNotNil(collect)
            XCTAssertNotEqual(collect!.config, context.config)
        }
    }

    func testConfigStaysTheSameWithoutCachedSettings() {
        let retriever = MockPublishSettingsRetriever()
        context.config.dispatchers = [Dispatchers.Collect]
        config.shouldUseRemotePublishSettings = true
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let collect = modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})
            XCTAssertNotNil(collect)
            XCTAssertEqual(collect?.config, context.config)
        }
    }

    func testCollectIsDisabledWithPublishSettings() {
        config.shouldUseRemotePublishSettings = true
        var defaultSettings = RemotePublishSettings()
        defaultSettings.collectEnabled = false
        let retriever = MockPublishSettingsRetriever(cachedSettings: defaultSettings)
        context.config.dispatchers = [Dispatchers.Collect]
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let collect = modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})
            XCTAssertNil(collect)
        }
    }
    #if os(iOS)
    func testTagManagementIsDisabledWithPublishSettings() {
        config.shouldUseRemotePublishSettings = true
        var defaultSettings = RemotePublishSettings()
        defaultSettings.tagManagementEnabled = false
        let retriever = MockPublishSettingsRetriever(cachedSettings: defaultSettings)
        context.config.dispatchers = [Dispatchers.Collect, Dispatchers.TagManagement]
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let collect = modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})
            let tagManagement = modulesManager.dispatchers.first(where: { $0.id == ModuleNames.tagmanagement})
            XCTAssertNotNil(collect)
            XCTAssertNil(tagManagement)
        }
    }
    #endif

    func testCollectIsDisabledWhenUpdatingPublishSettings() {
        config.shouldUseRemotePublishSettings = true
        var defaultSettings = RemotePublishSettings()
        let retriever = MockPublishSettingsRetriever(cachedSettings: defaultSettings)
        context.config.dispatchers = [Dispatchers.Collect]
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let getCollect = {modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})}
            XCTAssertNotNil(getCollect())
            defaultSettings.collectEnabled = false
            modulesManager.didUpdate(defaultSettings)
            XCTAssertNil(getCollect())
        }
    }
    #if os(iOS)
    func testTagManagementIsDisabledWhenUpdatingPublishSettings() {
        config.shouldUseRemotePublishSettings = true
        var defaultSettings = RemotePublishSettings()
        let retriever = MockPublishSettingsRetriever(cachedSettings: defaultSettings)
        context.config.dispatchers = [Dispatchers.Collect, Dispatchers.TagManagement]
        TealiumQueues.backgroundSerialQueue.sync {
            let modulesManager = getModulesManager(context, remotePublishSettingsRetriever: retriever)
            let getCollect = {modulesManager.dispatchers.first(where: { $0.id == ModuleNames.collect})}
            let getTagManagement = {modulesManager.dispatchers.first(where: { $0.id == ModuleNames.tagmanagement})}
            XCTAssertNotNil(getCollect())
            XCTAssertNotNil(getTagManagement())
        
            defaultSettings.tagManagementEnabled = false
            modulesManager.didUpdate(defaultSettings)
            XCTAssertNotNil(getCollect())
            XCTAssertNil(getTagManagement())
        }
    }
    #endif
}

extension TealiumModulesManagerTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

}

class DummyDispatchManagerRequestTrack: DispatchManagerProtocol {
    
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?
    
    var timedEventScheduler: Schedulable?

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdate"]?.fulfill()
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig, diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {
        XCTAssertTrue(request.trackDictionary.count > 0)
        XCTAssertNotNil(request.trackDictionary["request_uuid"])
        TealiumExpectations.expectations["requestTrack"]?.fulfill()
    }

    func handleDequeueRequest(reason: String) {
    }
    func checkShouldQueue(request: inout TealiumTrackRequest) -> Bool {
        return true
    }

}

class DummyDispatchManagerSendTrack: DispatchManagerProtocol {
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?
    
    var timedEventScheduler: Schedulable?

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdate"]?.fulfill()
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig, diskStorage: TealiumDiskStorageProtocol? = nil) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {
        XCTAssertTrue(request.trackDictionary.count > 0)
        XCTAssertNotNil(request.trackDictionary["request_uuid"])
        TealiumExpectations.expectations["sendTrack"]?.fulfill()
    }

    func handleDequeueRequest(reason: String) {

    }
    func checkShouldQueue(request: inout TealiumTrackRequest) -> Bool {
        return true
    }

}


struct MockPublishSettingsRetriever: TealiumPublishSettingsRetrieverProtocol {
    var cachedSettings: RemotePublishSettings?
    
    func refresh() {
        
    }
}
