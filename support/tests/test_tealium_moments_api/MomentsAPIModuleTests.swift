//
//  MomentsAPIModuleTests.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

@testable import TealiumMomentsAPI
@testable import TealiumCore
import XCTest

class TealiumMomentsAPIModuleTests: XCTestCase {
    
    let mockDataLayer = DummyDataManager()
    
    var tealium: Tealium!
    
    
    func waitOnTealiumSerialQueue<T>(_ block: () -> T) -> T {
        return TealiumQueues.backgroundSerialQueue.sync {
            return block()
        }
    }

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    func testModuleInitializationWithMissingRegion() {
        let contextWithoutRegion = TealiumContext(config: testTealiumConfig, dataLayer: mockDataLayer)
        let _ = TealiumMomentsAPIModule(context: contextWithoutRegion, delegate: nil, diskStorage: nil) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! MomentsError, MomentsError.missingRegion, "Expected MomentsError for missing region")
            case .success:
                XCTFail("Initialization should fail without region")
            }
        }
    }
    
    func testSuccessfulModuleInitialization() {
        testTealiumConfig.momentsAPIRegion = .germany
        let context = TealiumContext(config: testTealiumConfig, dataLayer: mockDataLayer)
        let _ = TealiumMomentsAPIModule(context: context, delegate: nil, diskStorage: nil) { result in
            switch result.0 {
            case .failure:
                XCTFail("Exepected success")
            case .success:
                XCTAssertTrue(true, "Initialization succeeded")
            }
        }
    }
    
    func testVisitorIDIsUpdated() {
        let tealiumInitialized = expectation(description: "Tealium is initialized")
        testTealiumConfig.momentsAPIRegion = .germany
        testTealiumConfig.collectors = [Collectors.AppData]
        tealium = Tealium(config: testTealiumConfig) { _ in
            tealiumInitialized.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [tealiumInitialized], timeout: 1.0)
        }

        let idProvider = tealium!.appDataModule?.visitorIdProvider
        let initialVisitorId = "123456"
        idProvider!.publishVisitorId(initialVisitorId, andUpdateStorage: false)
        let context = tealium.context!
        let moduleInitializedExpectation = expectation(description: "module initialized")
        let module = TealiumMomentsAPIModule(context: context, delegate: nil, diskStorage: nil) { _ in
            moduleInitializedExpectation.fulfill()
        }
        
        waitOnTealiumSerialQueue {
            wait(for: [moduleInitializedExpectation], timeout: 1.0)
        }
        XCTAssertEqual(module.momentsAPI?.visitorId!, initialVisitorId)
        let newVisitorId = "newvisitor"
        idProvider!.publishVisitorId(newVisitorId, andUpdateStorage: false)
        let visitorIdExpectation = expectation(description: "visitorid")

        TealiumQueues.backgroundSerialQueue.async {
            XCTAssertEqual(newVisitorId, module.momentsAPI!.visitorId!)
            visitorIdExpectation.fulfill()
        }
        waitOnTealiumSerialQueue {
            wait(for: [visitorIdExpectation], timeout: 1.0)
        }
    }
    
    
}
