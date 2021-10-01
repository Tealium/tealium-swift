//
//  TealiumInstanceManagerTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class TealiumInstanceManagerTests: XCTestCase {

    let manager = TealiumInstanceManager.shared
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateTealium() {
        let config = TealiumConfig(account: "a", profile: "b", environment: "dev")
        var tealium : Tealium? = Tealium(config: config)
        XCTAssertNotNil(tealium) // Silence warning
        let key = manager.generateInstanceKey(for: config)
        XCTAssertNotNil(manager.getInstanceByName(key))
        tealium = nil
        XCTAssertNotNil(manager.getInstanceByName(key))
        manager.removeInstanceForKey(key)
        XCTAssertNil(manager.getInstanceByName(key))
    }

    func testOpenUrl() {
        let url = URL(string: "www.google.it")!
        let manager = TealiumInstanceManager()
        let firstReceiveExp = expectation(description: "Will receive url")
        let secondReceiveExp = expectation(description: "Will receive url too")
        let thirdReceiveExp = expectation(description: "Will receive url too")
        manager.onOpenUrl.subscribe { url in
            firstReceiveExp.fulfill()
        }
        manager.didOpenUrl(url)
        manager.onOpenUrl.subscribe { url in
            secondReceiveExp.fulfill()
        }
        manager.onOpenUrl.subscribe { url in
            thirdReceiveExp.fulfill()
        }
        wait(for: [firstReceiveExp, secondReceiveExp, thirdReceiveExp], timeout: 0)
    }
    
    
    func testDidOpenUrlToDataLayer() {
        let config = testTealiumConfig.copy
        let tealium = Tealium(config: config, dataLayer: MockInMemoryDataLayer(), modulesManager: nil, migrator: nil, enableCompletion: nil)
        
        let expectationRequest = expectation(description: "emptyEventDetected")
        let url = URL(string: "https://www.google.it")!
        TealiumInstanceManager.shared.didOpenUrl(url)
        
        TealiumQueues.backgroundSerialQueue.async {
            let dataLayerUrl = tealium.dataLayer.all[TealiumKey.deepLinkURL] as? String
            expectationRequest.fulfill()
            XCTAssertEqual(url.absoluteString, dataLayerUrl)
        }
        waitForExpectations(timeout: 4.0, handler: nil)
    }

}
