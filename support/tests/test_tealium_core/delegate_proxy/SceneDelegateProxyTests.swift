//
//  SceneDelegateProxyTests.swift
//  TealiumSceneDelegateProxyTests-iOS
//
//  Created by Enrico Zannini on 21/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest

@available(iOS 13, *)
class SceneDelegateProxyTests: BaseProxyTests {
    
    func testConnectSessionOperUrl() async throws {
        let teal = tealium!
        let url = URL(string: "https://my-test-app.com/?test_param=true")!
        await sendWillConnectWithOptions(MockConnectionOptions(url: url, isActivity: false))
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true")
        }
    }
    
    func testConnectSessionUniversalLink() async {
        let teal = tealium!
        let url = URL(string: "https://www.tealium.com/universalLink/?universal_link=true")!
        await sendWillConnectWithOptions(MockConnectionOptions(url: url, isActivity: true))
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_universal_link"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true")
        }
    }

    @MainActor
    func sendWillConnectWithOptions(_ options: MockConnectionOptions) {
        UIApplication.shared.manualSceneWillConnect(with: options)
    }
}
