//
//  TealiumConnectivityTests.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumConnectivityTests: XCTestCase {

    var defaultTealiumConfig: TealiumConfig { TealiumConfig(account: "tealiummobile",
                                                            profile: "demo",
                                                            environment: "dev",
                                                            options: nil)
    }

    var legacyConnectivityRefreshEnabled: ConnectivityModule {
        let config = defaultTealiumConfig.copy
        config.connectivityRefreshEnabled = true
        let context = TestTealiumHelper.context(with: config)
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        connectivity.connectivityMonitor = LegacyConnectivityMonitor(config: config) { _ in

        }
        return connectivity
    }

    var legacyConnectivityRefreshDisabled: ConnectivityModule {
        let config = defaultTealiumConfig.copy
        config.connectivityRefreshEnabled = false
        let context = TestTealiumHelper.context(with: config)
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        connectivity.connectivityMonitor = LegacyConnectivityMonitor(config: config) { _ in

        }
        return connectivity
    }

    var nwPathConnectivity: ConnectivityModule {
        let config = defaultTealiumConfig.copy
        let context = TestTealiumHelper.context(with: config)
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil) { _ in }
        return connectivity
    }
    
    func nwPathConnectivity(with mock: ConnectivityMonitorProtocol) -> ConnectivityModule {
        let config = defaultTealiumConfig.copy
        let context = TestTealiumHelper.context(with: config)
        let connectivity = ConnectivityModule(context: context, delegate: nil, diskStorage: nil, connectivityMonitor: mock)
        return connectivity
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Legacy test only
    func testInitNoRefresh() {
        let connectivity = legacyConnectivityRefreshDisabled
        XCTAssertNil((connectivity.connectivityMonitor as! LegacyConnectivityMonitor).timer, "Timer unexpectedly enabled")
    }

    // Legacy test only
    func testInitWithRefresh() {
        let connectivity = legacyConnectivityRefreshEnabled
        XCTAssertNotNil((connectivity.connectivityMonitor as! LegacyConnectivityMonitor).timer, "Timer unexpectedly nil")
    }

    func testCurrentConnectionTypeWifi() {
        let expectation = self.expectation(description: "connection type")
        nwPathConnectivity.connectivityMonitor = MockConnectivityMonitorIsConnectedWifi(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let data = connectivity.data!

            XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeWifi)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrentConnectionTypeCellular() {
        let expectation = self.expectation(description: "connection type")
        let mock = MockConnectivityMonitorIsConnectedCellular(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity(with: mock)
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let data = connectivity.data!

            XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeCell)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrentConnectionTypeWired() {
        let expectation = self.expectation(description: "connection type")
        let mock = MockConnectivityMonitorIsConnectedWired(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity(with: mock)
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let data = connectivity.data!

            XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeWired)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrentConnectionTypeNone() {
        let expectation = self.expectation(description: "connection type")
        let mock = MockConnectivityMonitorNotConnected(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity(with: mock)
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let data = connectivity.data!

            XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeNone)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testCurrentConnectionTypeLegacy() {
        let connectivity = legacyConnectivityRefreshEnabled
        let data = connectivity.data!
        XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeWifi)
    }
    
    func testCheckIsConnectedTrue() {
        let expectation = self.expectation(description: "isConnectedTrue")
        nwPathConnectivity.connectivityMonitor = MockConnectivityMonitorIsConnectedWifi(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            connectivity.checkIsConnected { result in
                switch result {
                case .success(let isConnected):
                    XCTAssertTrue(isConnected)
                    expectation.fulfill()
                case .failure:
                    XCTFail("Should be connected")
                }
            }
        }
        self.wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckIsConnectedFalse() {
        let expectation = self.expectation(description: "isConnectedFalse")
        let mock = MockConnectivityMonitorNotConnected(config: defaultTealiumConfig, completion: { _ in })
        let connectivity = nwPathConnectivity(with: mock)
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            connectivity.checkIsConnected { result in
                switch result {
                case .success(_):
                    XCTFail("Should not be connected")
                case .failure(let error):
                    XCTAssertEqual(error as! TealiumConnectivityError, TealiumConnectivityError.noConnection)
                    expectation.fulfill()
                }
            }
        }
        self.wait(for: [expectation], timeout: 1.0)
    }

    func testCheckIsConnectedLegacy() {
        let connectivity = legacyConnectivityRefreshDisabled
        connectivity.checkIsConnected { result in
            switch result {
            case .success(let isConnected):
                XCTAssertTrue(isConnected)
            case .failure:
                XCTFail("Should be connected")
            }
        }
    }
    
    func testCheckIsConnectedURLTask() {
        let config = defaultTealiumConfig.copy
        let connectivity = legacyConnectivityRefreshDisabled
        let connectivityMonitor = LegacyConnectivityMonitor(config: config, completion: { _ in

        }, urlSession: MockURLSessionConnectivityWithConnection())

        connectivity.connectivityMonitor = connectivityMonitor

        connectivityMonitor.checkConnectionFromURLSessionTask { result in
            switch result {
            case .success(let isConnected):
                XCTAssertTrue(isConnected)
            case .failure:
                XCTFail("Should be connected")
            }
        }
    }

    func testCheckIsConnectedNoConnectionURLTask() {
        let config = defaultTealiumConfig.copy
        let connectivity = legacyConnectivityRefreshDisabled
        let connectivityMonitor = LegacyConnectivityMonitor(config: config, completion: { _ in

        }, urlSession: MockURLSessionConnectivityNoConnection())

        connectivity.connectivityMonitor = connectivityMonitor

        connectivityMonitor.checkConnectionFromURLSessionTask { result in
            switch result {
            case .success:
                XCTFail("Should not be connected")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        }
    }

    // Legacy test only
    func testDefaultConnectivityInterval() {
        let connectivity = legacyConnectivityRefreshEnabled
        XCTAssertEqual((connectivity.connectivityMonitor as! LegacyConnectivityMonitor).timer?.timeInterval, TimeInterval(exactly: ConnectivityConstants.defaultInterval), "Unexpected default time interval")
    }

    // Legacy test only
    func testOverriddenConnectivityInterval() {
        let config = defaultTealiumConfig.copy
        config.connectivityRefreshInterval = 5

        let connectivity = LegacyConnectivityMonitor(config: config) { _ in

        }

        XCTAssertEqual(connectivity.timer?.timeInterval, 5.0, "Unexpected default time interval")
    }

}

class MockConnectivityMonitorIsConnectedWifi: ConnectivityMonitorProtocol {
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
    }

    var currentConnnectionType: String? = "wifi"
    
    var isConnected: Bool? = true
    
    var isExpensive: Bool?
    
    var isCellular: Bool?
    
    var isWired: Bool?
    
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        completion(.success(true))
    }
    
}

class MockConnectivityMonitorIsConnectedWired: ConnectivityMonitorProtocol {
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
    }

    var currentConnnectionType: String? = "wired"
    
    var isConnected: Bool? = true
    
    var isExpensive: Bool?
    
    var isCellular: Bool?
    
    var isWired: Bool? = true
    
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        completion(.success(true))
    }
    
}


class MockConnectivityMonitorIsConnectedCellular: ConnectivityMonitorProtocol {
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
    }

    var currentConnnectionType: String? = "cellular"
    
    var isConnected: Bool? = true
    
    var isExpensive: Bool?
    
    var isCellular: Bool? = true
    
    var isWired: Bool?
    
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        completion(.success(true))
    }
    
}


class MockConnectivityMonitorNotConnected: ConnectivityMonitorProtocol {
    
    var config: TealiumConfig
    
    required init(config: TealiumConfig, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
    }

    var currentConnnectionType: String? = "none"
    
    var isConnected: Bool? = false
    
    var isExpensive: Bool?
    
    var isCellular: Bool?
    
    var isWired: Bool?
    
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        completion(.failure(TealiumConnectivityError.noConnection))
    }
    
}
