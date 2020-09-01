//
//  TealiumRemoteCommandTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class TealiumRemoteCommandTests: XCTestCase {

    var remoteCommand: RemoteCommand!
    var helper = TestTealiumHelper()
    var processRemoteCommandRequestCounter = 0

    override func setUpWithError() throws {
        remoteCommand = RemoteCommand(commandId: "test", description: "Test", completion: { _ in
            // ...
        })
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDelegateMethod() {
        let expect = expectation(description: "delegate method is executed via the complete method")
        let mockDelegate = MockRemoteCommandDelegate()
        RemoteCommandsManager.pendingResponses.value["123"] = true
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = RemoteCommandResponse(request: urlRequest) else {
            return
        }
        remoteCommand.delegate = mockDelegate
        mockDelegate.asyncExpectation = expect

        remoteCommand.complete(with: response)

        waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }

            guard let result = mockDelegate.remoteCommandResult else {
                XCTFail("Expected delegate to be called")
                return
            }
            XCTAssertNotNil(result)
        }
    }

    func testSendRemoteCommandResponse() {
        RemoteCommandsManager.pendingResponses.value["123"] = true
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = RemoteCommandResponse(request: urlRequest) else {
            return
        }
        RemoteCommand.sendRemoteCommandResponse(for: "test", response: response, delegate: self)
        XCTAssertNil(RemoteCommandsManager.pendingResponses.value["123"])
    }

    func testSendRemoteCommandResponseReturns() {
        // Returns when response is not expected type of `RemoteCommandResponse`
        let mockResponse = MockTealiumRemoteCommandResponse()
        RemoteCommand.sendRemoteCommandResponse(for: "test", response: mockResponse, delegate: self)
        XCTAssertEqual(self.processRemoteCommandRequestCounter, 0)

        // Returns when responseId is nil
        let urlString = "tealium://test?request={\"config\":{\"something\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = RemoteCommandResponse(request: urlRequest) else {
            return
        }

        RemoteCommand.sendRemoteCommandResponse(for: "test", response: response, delegate: self)
        XCTAssertEqual(self.processRemoteCommandRequestCounter, 0)

        // Returns when pendingResponse is false
        let urlString2 = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{}}"
        guard let escapedString2 = urlString2.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString2)")
            return
        }
        guard let url2 = URL(string: escapedString2) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest2 = URLRequest(url: url2)

        guard let response2 = RemoteCommandResponse(request: urlRequest2) else {
            return
        }

        RemoteCommandsManager.pendingResponses.value["123"] = false
        RemoteCommand.sendRemoteCommandResponse(for: "test", response: response2, delegate: self)
        XCTAssertNotNil(RemoteCommandsManager.pendingResponses.value["123"])
        XCTAssertEqual(self.processRemoteCommandRequestCounter, 0)

    }

    func testRemoteCommandResponse() {
        let commandId = "test"
        let responseId = "123"
        let expectedJSKey = "try { utag.mobile.remote_api.response[\'\(commandId)\'][\'\(responseId)\']('204',\'{\"hello\":\"world\"}\')}catch(err){console.error(err)}".replacingOccurrences(of: " ", with: "")

        let urlString = "tealium://\(commandId)?request={\"config\":{\"response_id\":\"\(responseId)\"}, \"payload\":{\"tealium_event\": \"launch\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)
        guard let response = RemoteCommandResponse(request: urlRequest) else {
            return
        }
        let dict = ["hello": "world"]
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: dict, options: [])
            response.data = data
        } catch {
            print(error)
        }

        let commandResponseDict = RemoteCommand.remoteCommandResponse(for: commandId, response: response)!
        let actualJSKey = (commandResponseDict[RemoteCommandsKey.jsCommand] as! String).replacingOccurrences(of: " ", with: "")

        XCTAssertEqual(actualJSKey, expectedJSKey)
    }

    func testRemoteCommandResponseReturnsWhenResponseIdNil() {

        let urlString = "tealium://test?request={\"config\":{\"something\":\"123\"}, \"payload\":{}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        guard let response = RemoteCommandResponse(request: urlRequest) else {
            return
        }

        let result = RemoteCommand.remoteCommandResponse(for: "test", response: response)

        XCTAssertNil(result)

    }

}

extension TealiumRemoteCommandTests: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {
        if request is TealiumRemoteCommandRequestResponse {
            self.processRemoteCommandRequestCounter += 1
        }
    }
}
