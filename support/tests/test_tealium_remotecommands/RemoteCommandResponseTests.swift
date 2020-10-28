//
//  RemoteCommandResponseTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumRemoteCommands
import XCTest

class RemoteCommandResponseTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitWithURLStringSetsPayload() {
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let response = RemoteCommandResponse(urlString: escapedString) else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        XCTAssert(NSDictionary(dictionary: response.payload!).isEqual(to: ["hello": "world"]))

    }

    func testInitWithBadURLStringReturnsNil() {
        let unescapedURLString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        let response = RemoteCommandResponse(urlString: unescapedURLString)
        XCTAssertNil(response)
    }

    func testInitNoRequestDataReturnsNil() {
        let urlString = "tealium://test?something123&norequestdata=true"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let response = RemoteCommandResponse(request: urlRequest)

        XCTAssertNil(response)
    }

    func testInitNoConfigDataInRequestReturnsNil() {
        let urlString = "tealium://test?request={\"something\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let response = RemoteCommandResponse(request: urlRequest)

        XCTAssertNil(response)
    }

    func testInitNoPayloadDataInRequestReturnsNil() {
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"something\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }
        guard let url = URL(string: escapedString) else {
            XCTFail("Could not create URL from string: \(urlString)")
            return
        }
        let urlRequest = URLRequest(url: url)

        let response = RemoteCommandResponse(request: urlRequest)

        XCTAssertNil(response)
    }

    func testConfigDictionaryFromRequest() {

        // Returns config
        var urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let response = RemoteCommandResponse(urlString: escapedString) else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        XCTAssert(NSDictionary(dictionary: response.config).isEqual(to: ["response_id": "123"]))

        // Returns empty
        guard let escapedStringEmpty = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let responseEmpty = RemoteCommandResponse(urlString: escapedStringEmpty) else {
            XCTFail("Something went wrong when creating the response")
            return
        }
        responseEmpty.urlRequest = nil

        XCTAssertTrue(responseEmpty.config.isEmpty)

    }

    func testResponseIdFromRequest() {

        // Returns responseId
        var urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let response = RemoteCommandResponse(urlString: escapedString), let responseId = response.responseId else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        XCTAssertEqual(responseId, "123")

        // Returns empty
        urlString = "tealium://test?request={\"config\":{\"something\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedStringEmpty = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let responseEmpty = RemoteCommandResponse(urlString: escapedStringEmpty) else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        XCTAssertNil(responseEmpty.responseId)

    }

    func testParametersDictionaryReturnsNil() {
        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let response = RemoteCommandResponse(urlString: escapedString) else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        let invalidJSONstring = "{\"number\":3465\"color\":\"red\",\"name\":\"Activity 4 with Images\"}"

        let result = response.dictionary(from: invalidJSONstring)

        XCTAssertNil(result)
    }

    func testDescription() {

        let expected = "<RemoteCommandResponse: config:[\"response_id\": 123],\nstatus:Optional(204),\npayload:Optional([\"hello\": world]),\nresponse: nil,\ndata:nil\nerror:nil>".replacingOccurrences(of: " ", with: "")

        let urlString = "tealium://test?request={\"config\":{\"response_id\":\"123\"}, \"payload\":{\"hello\": \"world\"}}"
        guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            XCTFail("Could not encode url string: \(urlString)")
            return
        }

        guard let response = RemoteCommandResponse(urlString: escapedString) else {
            XCTFail("Something went wrong when creating the response")
            return
        }

        let actual = response.description.replacingOccurrences(of: " ", with: "")

        XCTAssertEqual(actual, expected)

    }

}
