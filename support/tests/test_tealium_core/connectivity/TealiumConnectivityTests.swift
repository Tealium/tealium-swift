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

    func testCurrentConnectionType() {
        let expectation = self.expectation(description: "connection type")
        let connectivity = nwPathConnectivity
        // need to wait for NWPathMonitor callback to finish first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let data = connectivity.data!

            XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeWifi)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1.0)
    }

    func testCurrentConnectionTypeLegacy() {
        let connectivity = legacyConnectivityRefreshEnabled
        let data = connectivity.data!
        XCTAssertEqual(data[ConnectivityKey.connectionType] as! String, ConnectivityKey.connectionTypeWifi)
    }

    func testCheckIsConnected() {
        let expectation = self.expectation(description: "isConnected")
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

    //    func testDefaultConnectivityInterval() {
    //        let module = TealiumConnectivityModule(delegate: nil)
    //        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
    //        module.enable(request)
    //        module.isEnabled = true
    //        XCTAssertTrue(module.connectivity.timer?.timeInterval == TimeInterval(exactly: TealiumConnectivityConstants.defaultInterval))
    //    }
    //
    //    func testOverriddenConnectivityInterval() {
    //        let module = TealiumConnectivityModule(delegate: nil)
    //        let config = TestTealiumHelper().getConfig()
    //        let testInterval = 5
    //        config.setConnectivityRefreshInterval(testInterval)
    //        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
    //        module.enable(request)
    //        module.isEnabled = true
    //        XCTAssertTrue(module.connectivity.timer?.timeInterval == TimeInterval(exactly: testInterval))
    //    }

}
