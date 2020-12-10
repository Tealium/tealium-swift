//
//  PerformanceTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
@testable import TealiumLifecycle
@testable import TealiumVisitorService
import XCTest
#if os(iOS)
@testable import TealiumAttribution
@testable import TealiumAutotracking
@testable import TealiumLocation
//@testable import TealiumRemoteCommands
@testable import TealiumTagManagement
#endif

class PerformanceTests: XCTestCase {

    var tealium: Tealium!
    var config: TealiumConfig!
    var json: Data!
    let decoder = JSONDecoder()

    var standardMetrics: [XCTPerformanceMetric] = [.wallClockTime,
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_UserTime"),
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_RunTime"),
                                                   XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_SystemTime")]

    var allMetrics: [XCTPerformanceMetric] = [.wallClockTime,
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_UserTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_RunTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_SystemTime"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientVMAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TemporaryHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_HighWaterMarkForVMAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TotalHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_PersistentVMAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientHeapAllocationsKilobytes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_PersistentHeapAllocationsNodes"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_HighWaterMarkForHeapAllocations"),
                                              XCTPerformanceMetric(rawValue: "com.apple.XCTPerformanceMetric_TransientHeapAllocationsNodes")]

    override func setUpWithError() throws {
        json = TestTealiumHelper.loadStub(from: "big-visitor", type(of: self))
    }

    override func tearDownWithError() throws {
    }

    func testTimeToInitializeSimpleTealiumConfig() {

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
            self.stopMeasuring()
        }
    }

    func testTimeToInitializeTealiumConfigWithOptionalData() {

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment", dataSource: "testDatasource", options: [CollectKey.overrideCollectUrl: "https://6372509c65ca83cb33983be9c6f8f204.m.pipedream.net",
                                                                                                                                                           VisitorServiceConstants.visitorServiceDelegate: self])
            self.stopMeasuring()
        }
    }

    func testModulesManagerInitPerformance() {
        let eventDataManager = DataLayer(config: defaultTealiumConfig)

        let config = defaultTealiumConfig.copy
        //        config.loggerType = .custom(DummyLogger(config: config))
        let tealium = Tealium(config: config)
        let context = TealiumContext(config: config, dataLayer: eventDataManager, tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = ModulesManager(context)
            self.stopMeasuring()
        }
    }

    func testTimeToInitializeTealiumWithBaseModules() {
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        if #available(iOS 13.0, *) {
            self.measure(metrics: [//XCTCPUMetric(),
                //                XCTMemoryMetric(),
                XCTClockMetric(),
                //XCTStorageMetric(),
            ]) {
                let expectation = self.expectation(description: "init")
                tealium = Tealium(config: defaultTealiumConfig) { _ in
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 10.0)
                //                self.stopMeasuring()
            }
        } else {
            // Fallback on earlier versions
        }

        //        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
        //            tealium = Tealium(config: defaultTealiumConfig, modulesManager: modulesManager, enableCompletion: nil)
        //            self.stopMeasuring()
        //        }
    }

    func testTimeToInitializeTealiumWithAllModules() {
        defaultTealiumConfig.shouldUseRemotePublishSettings = false

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium = Tealium(config: defaultTealiumConfig, modulesManager: nil, enableCompletion: nil)
            self.stopMeasuring()
        }
    }

    func testTimeToDispatchTrackInCollect() {
        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, enableCompletion: nil)
        tealium.dataLayer.deleteAll()

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium.track(TealiumEvent("tester"))
            self.stopMeasuring()
        }

    }

    func testTimeToDispatchTrackInTagManagement() {
        //trackExpectation = expectation(description: "testTimeToDispatchTrackInTagManagement")

        defaultTealiumConfig.shouldUseRemotePublishSettings = false
        defaultTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: defaultTealiumConfig, enableCompletion: nil)
        tealium.dataLayer.deleteAll()

        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            tealium.track(TealiumEvent("tester"))
            self.stopMeasuring()
        }

    }

    // MARK: Individual Module Performance Tests
    func testAppDataModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = AppDataModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAppDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: defaultTealiumConfig, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = AppDataModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    #if os(iOS)
    func testAttributionModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = AttributionModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAttributionDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = AttributionModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testAutotrackingModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = AutotrackingModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testAutotrackingDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = AutotrackingModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }
    #endif

    func testCollectModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = CollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testConnectivityModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
            self.stopMeasuring()
        }
    }

    func testConnectivityHasViableConnection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            //            _ = module.hasViableConnection
            self.stopMeasuring()
        }
    }

    func testConsentManagerModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = ConsentManagerModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testConsentManagerDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = ConsentManagerModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testDeviceDataModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = DeviceDataModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testDeviceDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = DeviceDataModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    func testDispatchManagerInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let collect = CollectModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
        let dispatchers = [collect]
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = DispatchManager(dispatchers: dispatchers, dispatchValidators: nil, dispatchListeners: nil, connectivityManager: connectivity, config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testEventDataManagerInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = DataLayer(config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    //    func testEventDataCollectionWithStandardData() {
    //        let eventData = EventDataManager(config: defaultTealiumConfig)
    //        eventData.deleteAll()
    //        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
    //            _ = eventData.all
    //            self.stopMeasuring()
    //        }
    //    }

    func testEventDataCollectionWithLargePersistentDataSet() {
        let eventDataManager = DataLayer(config: defaultTealiumConfig)
        eventDataManager.deleteAll()
        let json = TestTealiumHelper.loadStub(from: "large-event-data", type(of: self))
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-YYYY HH:MM:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        guard let decoded = try? decoder.decode([DataLayerItem].self, from: json) else {
            return
        }
        decoded.forEach {
            eventDataManager.add(key: $0.key, value: $0.value, expiry: .forever)
        }
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = eventDataManager.all
            self.stopMeasuring()
        }
    }

    func testLifecycleModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = LifecycleModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testLifecycleDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = LifecycleModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }

    #if os(iOS)
    func testLocationModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = LocationModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testLocationDataCollection() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        let module = LocationModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = module.data
            self.stopMeasuring()
        }
    }
    #endif

    func testLoggerModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TealiumLogger(config: defaultTealiumConfig)
            self.stopMeasuring()
        }
    }

    func testLoggerWithOSLog() {
        defaultTealiumConfig.loggerType = .os
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
            self.stopMeasuring()
        }
    }

    func testLoggerWithPrintLog() {
        defaultTealiumConfig.loggerType = .print
        let logger = TealiumLogger(config: defaultTealiumConfig)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
            self.stopMeasuring()
        }
    }

    func testLoggerWithDummyLogger() {
        defaultTealiumConfig.loggerType = .custom(DummyLogger(config: testTealiumConfig))
        let logger = defaultTealiumConfig.logger!
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            let logRequest = TealiumLogRequest(title: "Hello There", message: "This is a test message", info: ["info1": "one", "info2": 123], logLevel: .info, category: .general)
            logger.log(logRequest)
            self.stopMeasuring()
        }
    }

    #if os(iOS)
    func testTagManagementModuleInit() {
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = TagManagementModule(config: defaultTealiumConfig, delegate: self, completion: { _ in })
            self.stopMeasuring()
        }
    }
    #endif

    func testVisitorServiceModuleInit() {
        let tealium = Tealium(config: defaultTealiumConfig)
        let context = TealiumContext(config: config, dataLayer: DataLayer(config: defaultTealiumConfig), tealium: tealium)
        self.measureMetrics(allMetrics, automaticallyStartMeasuring: true) {
            _ = VisitorServiceModule(context: context, delegate: self, diskStorage: nil, completion: { _ in })
            self.stopMeasuring()
        }
    }

    func testPerformanceVisitorProfileWithHelperMethods() throws {
        self.measure {
            let profile = try! decoder.decode(TealiumVisitorProfile.self, from: json)
            XCTAssertEqual(profile.audiences?.count, 188)
            XCTAssertEqual(profile.badges?.count, 256)
            XCTAssertEqual(profile.dates?.count, 448)
            XCTAssertEqual(profile.booleans?.count, 176)
            XCTAssertEqual(profile.arraysOfBooleans?.count, 80)
            XCTAssertEqual(profile.numbers?.count, 464)
            XCTAssertEqual(profile.arraysOfNumbers?.count, 48)
            XCTAssertEqual(profile.tallies?.count, 6)
            XCTAssertEqual(profile.strings?.count, 288)
            XCTAssertEqual(profile.arraysOfStrings?.count, 50)
            XCTAssertEqual(profile.setsOfStrings?.count, 100)
            XCTAssertEqual(profile.currentVisit?.dates?.count, 448)
            XCTAssertEqual(profile.currentVisit?.booleans?.count, 176)
            XCTAssertEqual(profile.currentVisit?.arraysOfBooleans?.count, 80)
            XCTAssertEqual(profile.currentVisit?.numbers?.count, 464)
            XCTAssertEqual(profile.currentVisit?.arraysOfNumbers?.count, 48)
            XCTAssertEqual(profile.currentVisit?.tallies?.count, 6)
            XCTAssertEqual(profile.currentVisit?.strings?.count, 288)
            XCTAssertEqual(profile.currentVisit?.arraysOfStrings?.count, 50)
            XCTAssertEqual(profile.currentVisit?.setsOfStrings?.count, 100)
        }
    }

}

extension PerformanceTests: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }
}

class DummyLogger: TealiumLoggerProtocol {
    var config: TealiumConfig?

    required init(config: TealiumConfig) {
        self.config = config
    }

    func log(_ request: TealiumLogRequest) {

    }

}
