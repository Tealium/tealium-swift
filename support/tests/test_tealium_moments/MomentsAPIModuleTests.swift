//
//  MomentsAPIModuleTests.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

@testable import TealiumMoments
@testable import TealiumCore
import XCTest

class TealiumMomentsAPIModuleTests: XCTestCase {
    
    var module: TealiumMomentsAPIModule!
    var mockContext: TealiumContext!
    var mockDelegate: ModuleDelegate!
    var mockDiskStorage: TealiumDiskStorageProtocol!
    var mockAPI: MomentsAPI!
    var mockDataLayer = DummyDataManager()

    override func setUpWithError() throws {
        super.setUp()
        mockContext = TealiumContext(config: testTealiumConfig, dataLayer: mockDataLayer)
        mockDelegate = MockModuleDelegate()
        mockDiskStorage = MockTealiumDiskStorage()
        mockAPI = MockMomentsAPI()
        module = TealiumMomentsAPIModule(context: mockContext, delegate: mockDelegate, diskStorage: mockDiskStorage) { _ in }
    }

    override func tearDownWithError() throws {
        module = nil
        super.tearDown()
    }

    func testModuleInitializationWithMissingRegion() {
        let configWithoutRegion = TealiumContext(config: testTealiumConfig, dataLayer: mockDataLayer)
        let failingModule = TealiumMomentsAPIModule(context: configWithoutRegion, delegate: nil, diskStorage: nil) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! MomentsError, MomentsError.missingRegion, "Expected MomentsError for missing region")
            case .success:
                XCTFail("Initialization should fail without region")
            }
        }
    }
}

// Mocks
class MockModuleDelegate: ModuleDelegate {
    func requestTrack(_ track: TealiumCore.TealiumTrackRequest) {
        
    }
    
    func requestDequeue(reason: String) {
        
    }
    
    func processRemoteCommandRequest(_ request: TealiumCore.TealiumRequest) {
        
    }
}

class MockMomentsAPI: MomentsAPI {
    var visitorId: String?

    func fetchEngineResponse(engineID: String, completion: @escaping (Result<EngineResponse, Error>) -> Void) {
    }
}
